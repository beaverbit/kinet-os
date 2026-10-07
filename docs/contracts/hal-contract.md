# HAL Contract

Every architecture HAL in `platform/hal/<arch>/` must implement a fixed
set of operations, each with a declared worst-case execution time (WCET).
A HAL that does not declare its costs is rejected by the build system; it
never reaches code review.

## Purpose

The HAL is the boundary between portable kernel code and
architecture-specific code. Because KinetOS promises bounded tail
latency, portability must not introduce variance: a HAL operation whose
cost is unknown is a source of jitter, and jitter defeats the design
goal.

Therefore every HAL operation declares its WCET, and the build system
enforces the declaration.

## Required operations

The following operations **must** be implemented by every HAL. Each is
declared in `platform/hal/<arch>/hal.toml`. The set is intentionally
small; anything architecture-specific that is not here belongs in a
driver, not in the HAL.

### Boot

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `boot_early`         | Enter the kernel from the bootloader.                |
| `boot_secondary`     | Bring up a secondary CPU.                            |

### CPU

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `cpu_id`             | Return the current CPU identifier.                   |
| `cpu_halt`           | Halt the current CPU until an interrupt.             |
| `cpu_relax`          | Hint the CPU that it is in a spin loop.              |
| `context_switch`     | Save the current context and restore another.        |

### Memory

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `mmu_init`           | Initialize the MMU for the kernel.                   |
| `mmu_map`            | Map a page in the current address space.             |
| `mmu_unmap`          | Unmap a page.                                        |
| `mmu_flush_tlb`      | Flush the TLB (full or per-page).                    |

### Interrupts

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `irq_init`           | Initialize the interrupt controller.                 |
| `irq_enable`         | Enable a specific IRQ line.                          |
| `irq_disable`        | Disable a specific IRQ line.                         |
| `irq_ack`            | Acknowledge an IRQ to the controller.                |
| `irq_eoi`            | Signal end-of-interrupt to the controller.           |

### Timers

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `timer_init`         | Initialize the system timer.                         |
| `timer_read`         | Read the current monotonic timestamp.                |
| `timer_set_deadline` | Program a one-shot timer for a deadline.             |

### Synchronization

| Operation            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `atomic_load`        | Atomic load with the required memory ordering.       |
| `atomic_store`       | Atomic store.                                        |
| `atomic_cas`         | Atomic compare-and-swap.                             |
| `memory_barrier`     | Full memory barrier.                                 |

Each operation above corresponds to a function the HAL must export and
a WCET the HAL must declare.

## Declaration format

Each HAL declares its costs in `platform/hal/<arch>/hal.toml`:

```toml
[hal]
arch = "x86_64"
reference_platform = "x86_64-reference"

[operations.boot_early]
wcet_ns = 15000

[operations.boot_secondary]
wcet_ns = 80000

[operations.cpu_id]
wcet_ns = 5

[operations.cpu_halt]
wcet_ns = 100

[operations.context_switch]
wcet_ns = 250
max_irq_disabled_ns = 400

[operations.mmu_map]
wcet_ns = 300
max_irq_disabled_ns = 500

[operations.irq_ack]
wcet_ns = 40

[operations.timer_read]
wcet_ns = 15

# ... one entry per required operation
```

The build system parses `hal.toml` and generates a C header with the
declared costs. The HAL implementation must not exceed them.

## Fields

For every operation:

- `wcet_ns` — worst-case execution time in nanoseconds, on the reference
  platform declared in `docs/contracts/wcet-analysis.md`.

Optional, when applicable:

- `max_irq_disabled_ns` — maximum time interrupts are disabled during the
  operation. Required for operations that run with interrupts disabled
  (context switch, TLB flush, MMU map/unmap).
- `may_fault` — `true` if the operation may cause a hardware fault
  (e.g., `mmu_map` on an invalid address). Default `false`. If `true`,
  the fault path must be declared.

## Where declarations live

```
platform/hal/
├── x86_64/
│   ├── hal.toml           # declared costs
│   ├── boot/
│   ├── cpu/
│   ├── mm/
│   ├── interrupts/
│   └── timers/
├── aarch64/
│   └── hal.toml
├── riscv64/
│   └── hal.toml
└── contracts/
    ├── required-operations.txt   # the list every HAL must implement
    └── README.md                 # this document's companion
```

The `contracts/` directory holds the machine-readable list of required
operations. The build system compares each HAL against it.

## Verification

Declared HAL WCETs are verified by:

1. **Static analysis** where possible. HAL code is small and has no
   recursion; static analysis should be the primary method.
2. **Adversarial measurement** on the reference platform, under the
   conditions declared in `docs/contracts/wcet-analysis.md`.
3. **Code review** — a HAL operation whose implementation does not match
   its declaration is rejected on review, even if measurements pass.

A HAL whose measured WCET exceeds its declared WCET by more than the
tolerance declared in `docs/contracts/wcet-analysis.md` is rejected.

## Build enforcement

The build system enforces the contract:

- **Completeness.** Every operation in `required-operations.txt` must
  have an entry in `hal.toml`. A missing entry is a build error.
- **Declaration.** Every operation in `hal.toml` must have a
  corresponding function in the HAL. A declaration without an
  implementation is a build error.
- **No undeclared operations.** A function exported by the HAL that is
  not in `required-operations.txt` is a build error. Architecture-specific
  code that is not part of the HAL belongs in a driver.

This makes the HAL contract mechanical: a HAL is either complete and
declared, or it does not build.

## What a HAL may not do

A HAL operation must be a **pure function of its inputs and the
hardware state**, with a bounded cost. It may not:

- Block, sleep, or wait for an event. HAL operations are called from
  contexts where blocking is not possible (early boot, interrupt
  handlers, context switch).
- Allocate memory. The HAL has no allocator.
- Call into the scheduler. The scheduler uses the HAL, not the reverse.
- Depend on another HAL operation's side effects, except where the
  required-operations list explicitly allows it (e.g., `mmu_flush_tlb`
  after `mmu_map`).
- Introduce variance not captured by its declared WCET. If a HAL
  operation's cost depends on data (e.g., cache behavior), the
  worst-case must be declared, not the average.

A HAL operation that violates any of these is rejected on review,
regardless of correctness.

## Adding a new architecture

To add a new architecture, implement every operation in
`required-operations.txt` and declare its WCET in `hal.toml`. The build
system will accept the HAL only when:

1. Every required operation is implemented.
2. Every operation has a declared `wcet_ns`.
3. No undeclared function is exported.
4. The CI measurement confirms declared costs within tolerance.

See `docs/hal-overview.md` for the procedure to add a new architecture
to the tree.

## Non-goals

- The HAL is not a driver interface. Drivers call the HAL; they do not
  implement it.
- The HAL does not abstract away architecture differences that affect
  timing. Where timing differs (e.g., TLB flush cost), the difference is
  declared, not hidden.
- The HAL does not provide a portable ABI. It provides a set of
  operations with declared costs; their signatures may vary slightly by
  architecture where the hardware requires it.

## Open questions

- Should `required-operations.txt` live in `contracts/` as a plain text
  file, or should the list be embedded in this document and extracted by
  CI? The current proposal is a separate text file for machine reading.
- How are optional operations declared? Some architectures have features
  others do not (e.g., hardware virtualization extensions). The current
  proposal has no optional operations; everything is required. If an
  architecture cannot implement one, it is not a valid KinetOS target.
- What is the process when a required operation is discovered to be
  too slow on a new architecture? Reject the architecture, or split the
  operation into a fast path and a slow path, each declared separately?
