# Kernel Decisions

Record of technical decisions for KinetOS. This file covers kernel architecture, scope, stack, memory, scheduling, and drivers.

---

## Decision 001: C + Assembly as primary stack

**Status:** Accepted

**Context:**
KinetOS targets tail latency (p99, p999) and predictability. The stack must be coherent with this goal: no runtime, no garbage collector, no abstraction layers that introduce unpredictable latency.

**Alternatives considered:**
1. C + Assembly (pure)
2. C + Assembly + Rust from the start
3. C + Assembly + high-level languages

**Decision:**
C + Assembly as primary stack. Rust reserved for critical modules in a future phase. High-level languages permanently discarded.

**Rationale:**
- **C**: full control over memory and hardware; minimal latency; predictability; portability.
- **Assembly**: mandatory for boot, context switch, and architecture-specific instructions; zero overhead.
- **Rust**: evaluated for critical modules (allocator, scheduler) in a future phase. `no_std` eliminates runtime, but introduces interop complexity with C.
- **High-level (Python, Java, Go, Node.js)**: discarded. Runtime, GC, and abstraction layers introduce unpredictable latency.

**Consequences:**
- Greater manual effort in memory management.
- Greater exposure to memory bugs.
- Full control over latency and system behavior.
- Portability to architectures with scarce resources.
- Rust can be introduced incrementally without rewriting the kernel.

**References:**
- Linux Kernel (C + Assembly)
- xv6 (C + Assembly)
- Redox OS (Rust, reference for future phase)
- SerenityOS (C++, architecture reference)

---

## Decision 002: Scope — tail latency, own category

**Status:** Accepted

**Context:**
KinetOS needs to define its scope in the operating systems ecosystem. The choice is between competing in general use (against Linux, FreeBSD, Windows) or focusing on a specific problem not solved by general-purpose OSes.

**Alternatives considered:**
1. General-purpose OS
2. Niche OS (tail latency)
3. Own category (low latency + predictability)

**Decision:**
Niche OS focused on tail latency, positioned in its own category: low latency + predictability. Not a competitor to general-purpose OSes.

**Rationale:**
- General-purpose = infinite scope, direct competition with Linux, FreeBSD, Windows.
- Niche = controlled scope, real problem, measurable differential.
- Tail latency (p99, p999) is an unsolved problem in general-purpose OSes.
- Applications: gaming, REST APIs, real-time networking, distributed systems, remote surgery, high-frequency trading, edge computing, critical embedded systems.
- As the world becomes more interactive, more workloads need predictable latency.

**Consequences:**
- Does not compete with Linux, FreeBSD, or Windows.
- Latency-oriented scheduler, not fairness.
- Priority for interactive workloads.
- Benchmarks focused on p99/p999, jitter, and predictability.

**References:**
- QNX (real-time)
- Zephyr (embedded)
- PusOS (edge computing)
- LITMUS^RT (deterministic Linux)

---

## Decision 003: Architecture — monolithic modular

**Status:** Accepted

**Context:**
KinetOS needs to define its kernel architecture. The choice is between monolithic, microkernel, or hybrid.

**Alternatives considered:**
1. Pure monolithic
2. Microkernel
3. Hybrid
4. Monolithic modular

**Decision:**
Monolithic modular.

**Rationale:**
- **Pure monolithic**: simpler, but hard to maintain and evolve.
- **Microkernel**: safer and modular, but introduces IPC overhead (unpredictable latency).
- **Hybrid**: compromise, but unnecessary complexity.
- **Monolithic modular**: single kernel in privileged space, organized into modules with clear interfaces. Combines monolithic performance with microkernel modularity.

**Consequences:**
- Drivers and subsystems run in kernel space.
- Clear interfaces between modules.
- Facilitates incremental evolution without rewriting.
- Maintains minimal and predictable latency.

**References:**
- Linux (monolithic modular)
- FreeBSD (monolithic modular)
- SerenityOS (monolithic modular)

---

## Decision 004: Target architecture — x86_64

**Status:** Accepted

**Context:**
KinetOS needs to define its initial target hardware architecture. The choice is between x86_64, ARM64, RISC-V, or multiple.

**Alternatives considered:**
1. x86_64
2. ARM64
3. RISC-V
4. Multiple from the start

**Decision:**
x86_64 as initial target architecture. Other architectures evaluated in a future phase.

**Rationale:**
- **x86_64**: dominant architecture; abundant documentation; mature QEMU; OSDev Wiki focused on it.
- **ARM64**: relevant, but documentation less accessible.
- **RISC-V**: promising, but ecosystem still maturing.
- **Multiple from the start**: infinite scope, unfeasible for a solo project.

**Consequences:**
- Boot, GDT, IDT, paging, and context switch specific to x86_64.
- Portability requires future refactoring.
- Focus on one architecture accelerates development.

**References:**
- Linux (supports multiple)
- xv6 (x86)
- SerenityOS (x86_64)

---

## Decision 005: Bootloader — Limine

**Status:** Accepted

**Context:**
KinetOS needs a bootloader to load the kernel. The choice is between writing a custom bootloader, using Multiboot2 + GRUB, or using Limine.

**Alternatives considered:**
1. Custom bootloader
2. Multiboot2 + GRUB
3. Limine

**Decision:**
Limine.

**Rationale:**
- **Custom bootloader**: unnecessary scope.
- **Multiboot2 + GRUB**: functional, but complex and has configuration overhead.
- **Limine**: modern, simple, with its own protocol; clear documentation; QEMU-compatible.

**Consequences:**
- Fast and simple boot.
- Less time spent on boot, more time on kernel.

**References:**
- Limine (https://github.com/limine-bootloader/limine)
- SerenityOS (uses Limine)

---

## Decision 006: Memory model — 4-level paging

**Status:** Accepted

**Context:**
KinetOS needs to define its virtual memory model. The choice is between segmentation, 2-level paging, 4-level paging, or 5-level paging.

**Alternatives considered:**
1. Segmentation
2. 2-level paging
3. 4-level paging (x86_64 standard)
4. 5-level paging

**Decision:**
4-level paging (x86_64 standard).

**Rationale:**
- **Segmentation**: obsolete on x86_64.
- **2-level paging**: insufficient for 64-bit addressing.
- **4-level paging**: x86_64 standard; supports 48-bit virtual addresses (256 TB).
- **5-level paging**: rare hardware; unnecessary complexity.

**Consequences:**
- Uses PML4, PDPT, PD, and PT.
- Supports 256 TB of virtual address space.
- Huge pages (2 MB, 1 GB) to reduce TLB misses.
- Alignment with x86_64 standard.

**References:**
- Intel SDM Volume 3A (paging)
- Linux (x86_64 uses 4 levels)

---

## Decision 007: Scheduler — tail-latency oriented

**Status:** Accepted

**Context:**
KinetOS needs to define its scheduling policy. The choice is between fairness (CFS-like), real-time (fixed priority), or tail-latency oriented.

**Alternatives considered:**
1. Fairness (CFS-like)
2. Real-time (fixed priority)
3. Tail-latency oriented

**Decision:**
Tail-latency oriented scheduler (p99, p999), not fairness or average throughput.

**Rationale:**
- **Fairness (CFS-like)**: optimizes average throughput and fairness, but not tail latency.
- **Real-time (fixed priority)**: guarantees deadlines, but does not adapt to variable interactive workloads.
- **Tail-latency oriented**: prioritizes predictability; reduces p99 and p999; adapts to variable loads.

**Consequences:**
- Priority for interactive tasks.
- CPU isolation for critical tasks.
- Fast preemption.
- Benchmarks focused on p99/p999, jitter, and predictability.
- Trade-off: average throughput may be lower than CFS on batch workloads.

**References:**
- CFS (Linux)
- LITMUS^RT (deterministic Linux)
- QNX (real-time)

---

## Decision 008: Drivers — in kernel space

**Status:** Accepted

**Context:**
KinetOS needs to define where drivers run. The choice is between kernel space (monolithic) or user space (microkernel).

**Alternatives considered:**
1. Kernel space (monolithic)
2. User space (microkernel)
3. Hybrid

**Decision:**
Drivers in kernel space.

**Rationale:**
- **Kernel space**: lower latency (no IPC), simpler, aligned with monolithic modular architecture.
- **User space**: greater isolation, but IPC overhead introduces unpredictable latency.
- **Hybrid**: unnecessary complexity.

**Consequences:**
- Drivers have full access to hardware.
- Greater risk of kernel failure due to driver bug.
- Lower latency in I/O operations.
- Alignment with low-latency goal.

**References:**
- Linux (drivers in kernel)
- QNX (drivers in userspace, different trade-off)

---

## Decision 009: Project philosophy — latency as a requirement

**Status:** Accepted

**Context:**
KinetOS needs to define its project philosophy. The choice is between latency as a requirement or latency as a consequence.

**Alternatives considered:**
1. Latency as a requirement
2. Latency as a consequence

**Decision:**
Latency as a requirement. Every design decision is evaluated by its impact on tail latency.

**Rationale:**
- **Latency as a consequence**: general-purpose OS approach; latency is optimized later.
- **Latency as a requirement**: KinetOS approach; latency guides all decisions from the start.

**Consequences:**
- Every feature is evaluated by its impact on latency.
- Benchmarks focused on p99/p999, jitter, predictability.
- Explicit trade-offs: throughput may be lower than general-purpose OSes.
- Clear philosophy guides project evolution.

**References:**
- QNX (latency as a requirement)
- LITMUS^RT (latency as a requirement)
- Linux (latency as a consequence, for contrast)

---

## Decision 010: Architecture — separation kernel (supersedes 003, 007, 008)

**Status:** Accepted

**Context:**
Decision 003 chose monolithic modular; Decision 007 chose a "tail-latency
oriented" scheduler; Decision 008 placed drivers in kernel space. After
writing `docs/design/execution-model.md`, `isolation-model.md`, and
`certification.md`, these decisions were found insufficient for the
certification target (DO-178C) and the tail-latency goal.

**Decision:**
KinetOS uses a **separation kernel** architecture:

- The certifiable kernel (`core/` + `platform/hal/` + certified drivers)
  is minimal and contains no drivers that are not part of the
  certification artifact.
- All other drivers run in isolated partitions
  (`platform/drivers/partitioned/`), under the driver contract.
- The scheduler is hierarchical: temporal partitions at the top level
  (ARINC 653-style), rate-monotonic inside each partition.
- Demand paging is not supported; all memory on the critical path is
  pre-faulted and pinned.

**Supersedes:** Decision 003 (monolithic modular), Decision 007
(tail-latency oriented scheduler), Decision 008 (drivers in kernel space).

**Rationale:**
- Certification requires a small, provable kernel. Monolithic modular
  does not provide this.
- Bounded tail latency requires bounded scheduling, which the temporal
  partition model provides and "tail-latency oriented" does not.
- Drivers in partitions contain faults; drivers in the kernel propagate
  them.

**References:**
- `docs/design/execution-model.md`
- `docs/design/isolation-model.md`
- `docs/contracts/certification.md`
- seL4, QNX (architectural references)

---

- **Date:** 2026-10-07
- **End of document.**
