# Kernel Decisions

Record of technical decisions for KinetOS. This file covers kernel architecture,
scope, stack, memory, scheduling, drivers, timing, and measurement.

---

## Decision 001: C + Assembly as primary stack

**Status:** Accepted

**Context:** KinetOS targets tail latency (p99, p999) and predictability. The
stack must be coherent with this goal: no runtime, no garbage collector, no
abstraction layers that introduce unpredictable latency.

**Alternatives considered:**

- C + Assembly (pure)
- C + Assembly + Rust from the start
- C + Assembly + high-level languages

**Decision:** C + Assembly as primary stack. Rust reserved for critical modules
in a future phase. High-level languages permanently discarded.

**Rationale:**

- C: full control over memory and hardware; minimal latency; predictability;
  portability.
- Assembly: mandatory for boot, context switch, and architecture-specific
  instructions; zero overhead.
- Rust: evaluated for critical modules (allocator, scheduler) in a future phase.
  `no_std` eliminates runtime, but introduces interop complexity with C.
- High-level (Python, Java, Go, Node.js): discarded. Runtime, GC, and abstraction
  layers introduce unpredictable latency.

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

**Date:** 2026-10-01

---

## Decision 002: Scope — tail latency, own category

**Status:** Accepted

**Context:** KinetOS needs to define its scope in the operating systems
ecosystem. The choice is between competing in general use (against Linux,
FreeBSD, Windows) or focusing on a specific problem not solved by general-purpose
OSes.

**Alternatives considered:**

- General-purpose OS
- Niche OS (tail latency)
- Own category (low latency + predictability)

**Decision:** Niche OS focused on tail latency, positioned in its own category:
low latency + predictability. Not a competitor to general-purpose OSes.

**Rationale:**

- General-purpose = infinite scope, direct competition with Linux, FreeBSD,
  Windows.
- Niche = controlled scope, real problem, measurable differential.
- Tail latency (p99, p999) is an unsolved problem in general-purpose OSes.
- Applications: gaming, REST APIs, real-time networking, distributed systems,
  remote surgery, high-frequency trading, edge computing, critical embedded
  systems.
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

**Date:** 2026-10-01

---

## Decision 003: Architecture — monolithic modular

**Status:** Accepted

**Context:** KinetOS needs to define its kernel architecture. The choice is
between monolithic, microkernel, or hybrid.

**Alternatives considered:**

- Pure monolithic
- Microkernel
- Hybrid
- Monolithic modular

**Decision:** Monolithic modular.

**Rationale:**

- Pure monolithic: simpler, but hard to maintain and evolve.
- Microkernel: safer and modular, but introduces IPC overhead (unpredictable
  latency).
- Hybrid: compromise, but unnecessary complexity.
- Monolithic modular: single kernel in privileged space, organized into modules
  with clear interfaces. Combines monolithic performance with microkernel
  modularity.

**Consequences:**

- Drivers and kernel subsystems run in kernel space.
- Filesystem and network stacks run outside the kernel core (see Decision 008
  and README for the boundary).
- Clear interfaces between modules.
- Facilitates incremental evolution without rewriting.
- Maintains minimal and predictable latency.

**References:**

- Linux (monolithic modular)
- FreeBSD (monolithic modular)
- SerenityOS (monolithic modular)

**Date:** 2026-10-01

---

## Decision 004: Target architecture — x86_64

**Status:** Accepted

**Context:** KinetOS needs to define its initial target hardware architecture.
The choice is between x86_64, ARM64, RISC-V, or multiple.

**Alternatives considered:**

- x86_64
- ARM64
- RISC-V
- Multiple from the start

**Decision:** x86_64 as initial target architecture. Other architectures
evaluated in a future phase (see Decision 012 in DECISIONS_PROJECT.md for ARM
Cortex-M).

**Rationale:**

- x86_64: dominant architecture; abundant documentation; mature QEMU; OSDev
  Wiki focused on it.
- ARM64: relevant, but documentation less accessible.
- RISC-V: promising, but ecosystem still maturing.
- Multiple from the start: infinite scope, unfeasible for a solo project.

**Consequences:**

- Boot, GDT, IDT, paging, and context switch specific to x86_64.
- Portability requires future refactoring.
- Focus on one architecture accelerates development.
- Timing and measurement are constrained by x86_64 commodity limitations (see
  Decision 012).

**References:**

- Linux (supports multiple)
- xv6 (x86)
- SerenityOS (x86_64)

**Date:** 2026-10-01

---

## Decision 005: Bootloader — Limine

**Status:** Accepted

**Context:** KinetOS needs a bootloader to load the kernel. The choice is
between writing a custom bootloader, using Multiboot2 + GRUB, or using Limine.

**Alternatives considered:**

- Custom bootloader
- Multiboot2 + GRUB
- Limine

**Decision:** Limine.

**Rationale:**

- Custom bootloader: unnecessary scope.
- Multiboot2 + GRUB: functional, but complex and has configuration overhead.
- Limine: modern, simple, with its own protocol; clear documentation;
  QEMU-compatible.

**Consequences:**

- Fast and simple boot.
- Less time spent on boot, more time on kernel.

**References:**

- Limine (https://github.com/limine-bootloader/limine)
- SerenityOS (uses Limine)

**Date:** 2026-10-01

---

## Decision 006: Memory model — 4-level paging

**Status:** Accepted

**Context:** KinetOS needs to define its virtual memory model. The choice is
between segmentation, 2-level paging, 4-level paging, or 5-level paging.

**Alternatives considered:**

- Segmentation
- 2-level paging
- 4-level paging (x86_64 standard)
- 5-level paging

**Decision:** 4-level paging (x86_64 standard).

**Rationale:**

- Segmentation: obsolete on x86_64.
- 2-level paging: insufficient for 64-bit addressing.
- 4-level paging: x86_64 standard; supports 48-bit virtual addresses (256 TB).
- 5-level paging: rare hardware; unnecessary complexity.

**Consequences:**

- Uses PML4, PDPT, PD, and PT.
- Supports 256 TB of virtual address space.
- Huge pages (2 MB, 1 GB) to reduce TLB misses.
- Alignment with x86_64 standard.

**References:**

- Intel SDM Volume 3A (paging)
- Linux (x86_64 uses 4 levels)

**Date:** 2026-10-01

---

## Decision 007: Scheduler — tail-latency oriented

**Status:** Accepted

**Context:** KinetOS needs to define its scheduling policy. The choice is
between fairness (CFS-like), real-time (fixed priority), or tail-latency
oriented.

**Alternatives considered:**

- Fairness (CFS-like)
- Real-time (fixed priority)
- Tail-latency oriented

**Decision:** Tail-latency oriented scheduler (p99, p999), not fairness or
average throughput.

**Rationale:**

- Fairness (CFS-like): optimizes average throughput and fairness, but not tail
  latency.
- Real-time (fixed priority): guarantees deadlines, but does not adapt to
  variable interactive workloads.
- Tail-latency oriented: prioritizes predictability; reduces p99 and p999;
  adapts to variable loads.

**Consequences:**

- Priority for interactive tasks.
- CPU isolation for critical tasks.
- Fast preemption.
- Benchmarks focused on p99/p999, jitter, and predictability (see Decision 010
  for measurement methodology).
- Trade-off: average throughput may be lower than CFS on batch workloads.

**References:**

- CFS (Linux)
- LITMUS^RT (deterministic Linux)
- QNX (real-time)

**Date:** 2026-10-01

---

## Decision 008: Drivers — in kernel space

**Status:** Accepted

**Context:** KinetOS needs to define where drivers run. The choice is between
kernel space (monolithic) or user space (microkernel).

**Alternatives considered:**

- Kernel space (monolithic)
- User space (microkernel)
- Hybrid

**Decision:** Device drivers run in kernel space. Filesystem and network stacks
run outside the kernel core, in a privileged service layer that shares the
kernel address space but has no access to the scheduler's critical path.

**Rationale:**

- Device drivers in kernel space: lower latency (no IPC), simpler, aligned with
  monolithic modular architecture.
- Filesystem and network outside the kernel core: isolates their worst-case
  behavior from the scheduler and memory subsystem. A pathological network
  stack does not add latency to a timer wakeup.
- User space drivers: greater isolation, but IPC overhead introduces
  unpredictable latency.
- Hybrid: unnecessary complexity.

**Consequences:**

- Device drivers have full access to hardware.
- Filesystem and network services cannot block the scheduler or the memory
  subsystem on their critical paths.
- Greater risk of kernel failure due to a buggy device driver.
- Lower latency in device I/O operations.
- Alignment with low-latency goal.

**References:**

- Linux (drivers in kernel)
- QNX (drivers in userspace, different trade-off)
- mTCP (userspace network stack, latency motivation)

**Date:** 2026-10-01

---

## Decision 009: Project philosophy — latency as a requirement

**Status:** Accepted

**Context:** KinetOS needs to define its project philosophy. The choice is
between latency as a requirement or latency as a consequence.

**Alternatives considered:**

- Latency as a requirement
- Latency as a consequence

**Decision:** Latency as a requirement. Every design decision is evaluated by
its impact on tail latency.

**Rationale:**

- Latency as a consequence: general-purpose OS approach; latency is optimized
  later.
- Latency as a requirement: KinetOS approach; latency guides all decisions from
  the start.

**Consequences:**

- Every feature is evaluated by its impact on latency.
- Benchmarks focused on p99/p999, jitter, predictability.
- Explicit trade-offs: throughput may be lower than general-purpose OSes.
- Clear philosophy guides project evolution.

**References:**

- QNX (latency as a requirement)
- LITMUS^RT (latency as a requirement)
- Linux (latency as a consequence, for contrast)

**Date:** 2026-10-01

---

## Decision 010: Time model and latency measurement

**Status:** Accepted

**Context:** KinetOS defines tail latency (p99, p999) as the primary metric
(Decision 007 and Decision 009). However, no existing decision defines *how*
latency is measured, *which* time source is used, or *what* "p99" means
operationally. Without this definition, the benchmarks promised in Decision 002
of DECISIONS_PROJECT.md cannot be implemented reproducibly, and measurements are
not comparable across runs, versions, or machines.

The problem is aggravated by the x86_64 commodity target: the architecture does
not offer a deterministic time source by default. The TSC (Time Stamp Counter)
may vary between cores, be affected by frequency (turbo boost, P-states,
C-states), and is not serializing without `RDTSCP` or `LFENCE`. HPET is more
stable but has high access cost. The APIC timer is suitable for events but not
for precise measurement.

**Alternatives considered:**

- TSC without invariant-TSC verification
- HPET as the primary source
- APIC timer as the primary source
- TSC with invariant-TSC verification and `RDTSCP` as the primary source, with
  HPET as fallback

**Decision:** TSC with invariant-TSC verification at boot, read via `RDTSCP`
(or `LFENCE; RDTSC` when `RDTSCP` is unavailable), as the primary timestamp
source. HPET as fallback when TSC invariance cannot be confirmed. The APIC
timer is used only to generate periodic events, not for measurement.

Latency is defined operationally as the interval between two explicit kernel
instrumentation points:

- **Wakeup latency:** interval between the entry of the interrupt handler that
  makes a task runnable (`irq_entry` timestamp) and the first instruction of the
  task in userspace (`task_resume` timestamp).
- **Syscall latency:** interval between `syscall_entry` and `syscall_return`
  timestamp.
- **Interrupt-to-task latency:** interval between `irq_entry` and
  `task_first_instruction` for the task unblocked by the interrupt.

p99 is the 99th percentile of the distribution of these samples in a run with
at least 10,000 samples. Jitter is defined as `p999 - p50` in the same run.

**Rationale:**

- **TSC with verified invariance:** highest-resolution source available on
  x86_64 (often sub-nanosecond), with the lowest read cost (`RDTSCP` is a few
  cycles). Invariance verification at boot eliminates the risk of inconsistent
  measurements between cores.
- **HPET as fallback:** ensures the system works on hardware where TSC is not
  invariant (old virtual machines, hardware without support). The higher cost
  is acceptable as a fallback.
- **APIC timer for events:** correct source for generating periodic interrupts,
  but its granularity (typically microseconds) is insufficient for latency
  measurement.
- **Explicit instrumentation points:** without an operational definition,
  "latency" is ambiguous. The three defined points cover the use cases cited in
  Decision 002 (REST APIs, networking, HFT, edge).
- **Minimum of 10,000 samples:** p999 requires at least 10,000 samples to have
  statistical meaning (the 10th largest value out of 10,000 is the p999).
  Smaller runs do not produce reliable p999.
- **Jitter as `p999 - p50`:** captures tail dispersion without depending on
  standard deviation, which is sensitive to outliers.

**Consequences:**

- Every latency benchmark uses TSC as the primary source.
- TSC invariance is verified at boot and logged. If it fails, HPET is used and
  the benchmark marks the run as "HPET-based".
- The three instrumentation points (`irq_entry`, `task_resume`,
  `syscall_entry`/`syscall_return`) are implemented in the "Latency measurement
  infrastructure" phase of the roadmap.
- Benchmarks with fewer than 10,000 samples are rejected.
- CPU frequency is pinned (governor `performance`, turbo disabled) during
  benchmarks. This is documented in every run.
- Comparisons across runs are valid only if both use the same time source and
  the same frequency configuration.
- On QEMU, TSC is virtualized and its invariance depends on the host. QEMU
  benchmarks are marked "emulated" and do not replace measurements on real
  hardware.

**References:**

- Intel SDM Volume 3B (Time Stamp Counter, RDTSCP)
- Intel SDM Volume 3A (HPET, APIC timer)
- Linux `arch/x86/kernel/tsc.c` (invariance verification)
- LITMUS^RT (latency measurement methodology)
- Xu et al., "Characterizing Tail Latency in Datacenters" (operational
  definition of p99/p999)

**Date:** 2026-10-11

---

## Decision 011: Driver WCET contract

**Status:** Accepted

**Context:** The KinetOS README states that "drivers declare a WCET" (Worst-Case
Execution Time). However, no existing decision defines *how* the WCET is
declared, *how* it is enforced, or *what happens* when it is violated. Decision
008 (drivers in kernel space) increases the kernel's exposure to driver bugs and
latency spikes but establishes no containment mechanism.

The problem is central to the project's philosophy: if latency is a requirement
(Decision 009), then a driver that violates its declared WCET is a design
failure, not an acceptable event. Without a detection and containment mechanism,
the declared WCET is only an unverifiable promise.

**Alternatives considered:**

- Declared WCET without verification (documentation only)
- Verification by static analysis (external tools)
- Verification by runtime watchdog with containment
- Verification by runtime watchdog without containment (log only)

**Decision:** Every driver declares a WCET in its registration structure, in
nanoseconds, for each exposed operation (init, read, write, ioctl, etc.). The
kernel maintains a per-driver watchdog, configured as `WCET * 2` (100% margin).
If an operation exceeds the watchdog:

1. An entry is recorded in a violation buffer accessible via a diagnostic
   interface.
2. A per-driver violation counter is incremented.
3. The driver is marked "unstable" and the kernel enters a degraded mode: new
   calls to the driver are rejected with `-EBUSY` until the counter is reset by
   an operator.

There is no forced containment of the in-flight operation (the kernel cannot
safely abort a kernel-space driver). Containment applies to the *next* call.

**Rationale:**

- **WCET declared per operation:** each operation has a distinct time profile. A
  single WCET per driver is too imprecise to be useful.
- **Watchdog at `WCET * 2`:** the 100% margin absorbs hardware variability
  (cache misses, bus contention) without masking real violations. A driver that
  consistently hits `2 * WCET` has a misdeclared WCET.
- **No forced containment:** aborting a kernel-space driver is unsafe (it may
  leave held locks, inconsistent memory). Containment on the next call is safe
  and sufficient to isolate the impact.
- **Degraded mode:** rejecting calls to the unstable driver prevents a faulty
  driver from contaminating the rest of the system, aligned with "isolation is
  structural" in the README.
- **Manual reset:** an operator (or an automated test) decides when the driver
  is trustworthy again. Automatic reset would mask bugs.

**Consequences:**

- The driver registration structure (`struct driver_ops` or equivalent) includes
  WCET fields per operation.
- The watchdog is implemented per driver, using the TSC (Decision 010) as the
  time source.
- The violation buffer is exposed via a diagnostic interface (to be defined:
  `/proc/kinet/drivers` or a dedicated syscall).
- Latency benchmarks include a scenario with an unstable driver to verify that
  isolation works.
- Drivers without a declared WCET are rejected at registration.
- In embedded mode (Decision 013 in DECISIONS_PROJECT.md, when implemented), the
  watchdog may be disabled by build flag to save resources, but the declared
  WCET remains mandatory.

**References:**

- QNX (driver timeouts and recovery)
- Linux `watchdog` subsystem (detection model, not containment)
- seL4 (WCET in isolated components)
- ARINC 653 (temporal partitioning)

**Date:** 2026-10-11

---

## Decision 012: What "bounds" means on x86_64 commodity

**Status:** Accepted

**Context:** The KinetOS README states:

> "Worst case is a requirement. Bounds are declared and provable, not observed
> post-hoc from benchmarks."

This vocabulary is borrowed from certifiable-systems domains (DO-178C,
ISO 26262, ARINC 653), where "provable bounds" requires deterministic hardware,
static WCET analysis (tools such as aiT, Bound-T), and a documented hardware
time model. None of these conditions is available on x86_64 commodity running on
QEMU.

On x86_64 commodity, there are sources of latency that the kernel does not
control:

- **SMI (System Management Interrupts):** firmware can steal CPU time without
  the kernel's knowledge. Typically 100µs+ per event.
- **Turbo boost and P-states:** variable frequency introduces non-deterministic
  latency.
- **DRAM refresh:** periodic memory refresh events.
- **TLB shootdown:** cross-core TLB invalidation has non-deterministic cost.
- **Cache misses:** the cache hierarchy introduces variable latency.
- **Host interference (QEMU):** under virtualization, timing depends on the
  host, not the guest.

Promising "provable bounds" in this environment is technically dishonest and
exposes the project to legitimate criticism.

**Alternatives considered:**

- Keep "provable bounds" and ignore the limitations
- Abandon the notion of bounds and focus only on averages
- Reformulate to "observable and bounded by watchdog under controlled
  conditions"
- Migrate the primary target to ARM Cortex-M (where bounds are more achievable)

**Decision:** Reformulate the project's vocabulary. "Bounds" in KinetOS means:

- **Declared:** each subsystem declares its latency budget in a decision or
  design document.
- **Observable:** benchmarks measure actual latency and compare against the
  declared budget.
- **Bounded by watchdog:** budget violations trigger a watchdog (Decision 011
  for drivers; an analogous mechanism for kernel subsystems).
- **Under controlled conditions:** benchmarks pin CPU frequency, disable turbo,
  isolate cores, and document the configuration. Comparisons across runs are
  valid only under the same configuration.
- **Not provable on x86_64 commodity:** the project explicitly acknowledges that
  provable bounds require deterministic hardware, and that x86_64 commodity does
  not offer it. The goal is to *minimize and document* uncontrolled latency, not
  to prove it does not exist.

The README is updated to reflect this definition. The word "provable" is
removed. The words "observable" and "bounded by watchdog" are introduced.

**Rationale:**

- **Technical honesty:** promising the impossible is worse than promising less.
  A research project gains credibility by acknowledging its limitations.
- **Focus on the controllable:** the kernel controls what happens inside it.
  What happens outside (SMI, hardware) is measured and documented, not solved.
- **Alignment with Decision 002 (scope):** "niche, not general-purpose". The
  niche is "observable and documented latency", not "proven latency".
- **Preparation for ARM Cortex-M (Decision 012 in DECISIONS_PROJECT.md):** on
  MCU, the "provable" vocabulary becomes appropriate again. The current
  reformulation is specific to x86_64 commodity and does not prevent the
  embedded mode from using stronger vocabulary.
- **Shielding against academic criticism:** the criticism "you cannot prove
  bounds on x86_64" ceases to be a problem because the project agrees with it.

**Consequences:**

- The README is updated: "Bounds are declared and provable" becomes "Bounds are
  declared, observable, and bounded by watchdog under controlled conditions".
- A "Sources of latency outside kernel control" section is added to `docs/`,
  documenting SMI, turbo, DRAM refresh, TLB shootdown, and QEMU.
- Benchmarks include an "uncontrolled latency" column separating kernel
  attributable latency from hardware/host attributable latency.
- On ARM Cortex-M (Decision 012 in DECISIONS_PROJECT.md, when implemented), the
  "provable" vocabulary may be reintroduced, with documented justification.
- Literature reviews and published papers use the reformulated vocabulary.

**References:**

- DO-178C (certification vocabulary, for contrast)
- ARINC 653 (temporal partitioning, for contrast)
- Intel SDM Volume 3B (SMI)
- QEMU documentation (non-deterministic timing)
- Xu et al., "Characterizing Tail Latency in Datacenters" (separation of
  controllable and uncontrollable latency)

**Date:** 2026-10-11

---

**End of document.**