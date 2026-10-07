# Interrupt Model

## Status

Proposed. This document defines how hardware interrupts are delivered,
handled, and how they interact with the scheduler. It depends on
`docs/design/execution-model.md`.

## Decision

Interrupt handling is **threaded**. Every hardware interrupt is split into
two parts:

1. **Top half** — runs in interrupt context, minimal, bounded. Does not
   call the scheduler. Does not allocate. Does not block.
2. **Bottom half (threaded handler)** — runs in a kernel thread, subject
   to the scheduler. May block, may allocate within the thread's budget.

This design bounds the time the system spends with interrupts disabled,
which is the primary source of tail latency in interrupt-driven systems.

## Top half

The top half is responsible for:

- Acknowledging the interrupt to the interrupt controller.
- Reading the minimum state required to hand off to the bottom half.
- Waking the threaded handler.
- Returning from interrupt.

It must not:

- Call the scheduler.
- Allocate memory.
- Acquire a lock that may be held by a thread.
- Execute for more than the declared WCET.

The WCET of every top-half handler is declared, per IRQ line, in
`platform/hal/<arch>/interrupts/`. A handler whose declared WCET is
exceeded in measurement is rejected on review.

## Bottom half

The bottom half is a kernel thread scheduled by the partition scheduler.
It runs with a priority assigned at configuration time. Its properties:

- May block (e.g., waiting for DMA completion).
- May allocate from a per-partition fixed pool.
- Subject to the partition's budget, like any other task.
- Preemptible at instruction boundaries except inside declared critical
  sections.

The bottom half is where the real work happens: processing network
packets, handling block I/O completion, reading sensor data. It runs
under the same scheduling guarantees as any other thread.

## Delivery latency

The maximum time from interrupt assertion to the start of the top half
is a **hardware property**, declared per architecture:

- x86_64 (APIC): declared in `platform/hal/x86_64/interrupts/`
- aarch64 (GIC): declared in `platform/hal/aarch64/interrupts/`
- riscv64 (PLIC/CLINT): declared in `platform/hal/riscv64/interrupts/`

This latency is dominated by hardware, not software. The kernel's
contribution is bounded by the time interrupts are disabled, which is
bounded by the top-half WCET.

## Interrupt disabling

Interrupts are disabled only:

- During the top half of another interrupt (nesting policy below).
- Inside declared critical sections in `core/sync/`.
- During context switch (minimal window, bounded).
- During boot, before the scheduler starts.

Interrupts are **not** disabled during:

- Bottom-half execution.
- User-space code.
- Partition scheduler decisions.
- System calls (except inside declared critical sections).

The maximum time interrupts are disabled is a declared property of the
kernel, verified in `validation/wcet/`.

## Nesting

Interrupts are nested by priority:

- Higher-priority interrupts preempt lower-priority top halves.
- Same-priority interrupts do not preempt each other.
- The priority assignment is architecture-specific and declared per IRQ
  line in the HAL.

Nesting depth is bounded. The bound is declared per architecture and
verified in `validation/wcet/`.

## Interaction with the scheduler

- The top half never calls the scheduler. It wakes the bottom half and
  returns.
- The scheduler is only invoked:
  - On explicit yield from a thread.
  - On blocking operation (IPC wait, mutex acquire).
  - On partition window boundary.
  - On timer interrupt (from the bottom half of the timer IRQ).
- This means the scheduler never runs in interrupt context. This is a
  deliberate design choice: it keeps the scheduler's own WCET provable.

## Spurious interrupts

A spurious interrupt (asserted without a pending device) is:

- Acknowledged.
- Counted per IRQ line.
- Not handed off to a bottom half.

The count is exposed via the partition's fault channel. A threshold can
be configured per line in `configs/<profile>/interrupts.toml`.

## Non-goals

- Direct interrupt-to-thread delivery (like `io_uring` or Linux's
  `threaded IRQ` with `IRQF_ONESHOT`) is not supported. All interrupts
  go through the top-half / bottom-half split.
- Nested bottom halves are not supported.
- Interrupt coalescing is a driver concern, not a kernel concern.

## Open questions

- Should top halves be allowed to acquire spinlocks with interrupts
  disabled? If yes, what is the maximum hold time? If no, how do two
  top halves on the same CPU synchronize?
- Should bottom halves be bound to a specific CPU, or migrate? Migration
  introduces cache effects that may affect WCET. Binding is safer but
  reduces throughput.
- What is the policy when a bottom half exceeds its declared WCET?
  Log and continue (like a partition budget overrun), or escalate?
