# KinetOS Research Notes

This document describes the research scope of KinetOS: the questions the
project investigates, the hypotheses it tests, the methodology used, and the
criteria by which a hypothesis would be considered falsified.

It is a living document. Sections marked *(to be written)* are placeholders for
content that will be filled as the project matures.

For architectural decisions, see `DECISIONS_KERNEL.md` and
`DECISIONS_PROJECT.md`. For the development plan, see `ROADMAP.md`.

---

## 1. Motivation

General-purpose operating systems (Linux, FreeBSD, Windows) optimize for average
throughput and fairness. Tail latency (p99, p999) is treated as a consequence of
design, not as a primary requirement. As interactive and distributed workloads
proliferate — REST APIs, real-time networking, high-frequency trading, remote
surgery, edge computing — worst-case predictability becomes a first-class
concern that general-purpose schedulers do not address.

KinetOS investigates whether a kernel designed from scratch around tail latency
can reduce p99/p999 relative to a general-purpose baseline, and — equally
important — what fraction of observed tail latency is attributable to the kernel
versus to factors outside kernel control (firmware, hardware, host under
virtualization).

A secondary question is whether the same design, ported to deterministic
hardware (ARM Cortex-M), can produce *provable* bounds rather than merely
*observable* ones. This is the motivation for the deferred embedded target
(Decision 012 in `DECISIONS_PROJECT.md`).

---

## 2. Scope

**In scope:**

- Kernel-level sources of tail latency: scheduler, interrupt handling, timer
  subsystem, memory allocation on the critical path.
- Measurement methodology for p99, p999, and jitter on x86_64 commodity
  hardware.
- Separation of kernel-attributable latency from hardware/host-attributable
  latency.
- Containment of driver misbehavior via WCET watchdog (Decision 011 in
  `DECISIONS_KERNEL.md`).
- Portability of the scheduler and time model to deterministic hardware.

**Out of scope:**

- Average throughput optimization.
- Fairness between workloads.
- POSIX or Linux ABI compatibility.
- General-purpose use.
- Production deployment.

See "What we do not promise" in `README.md` for the full list.

---

## 3. Hypotheses

Each hypothesis is stated so that it can be falsified. A hypothesis without a
falsification criterion is not a hypothesis; it is a design goal.

### H1: Scheduler design and tail latency

**Statement:** A scheduler designed around tail latency (priority for
interactive tasks, CPU isolation, fast preemption) reduces p999 wakeup latency
by at least 30% relative to CFS on a defined interactive workload, at the cost
of at most 20% reduction in average throughput on a defined batch workload.

**Falsification criterion:** If, under controlled conditions, the p999
reduction is less than 30%, or the throughput cost exceeds 20%, H1 is
falsified.

**Status:** Not yet testable. Requires: functional scheduler, time model
(Decision 010 in `DECISIONS_KERNEL.md`), and measurement infrastructure.

### H2: Attribution of tail latency

**Statement:** On x86_64 commodity hardware running KinetOS under a controlled
interactive workload, at least 40% of observed p999 wakeup latency is
attributable to sources outside kernel control (SMI, turbo boost, DRAM refresh,
TLB shootdown, cache behavior).

**Falsification criterion:** If, after instrumentation and controlled
measurement, the non-kernel-attributable fraction is below 40% or above 80%,
H2 is falsified. (Both directions matter: if it is too low, the kernel is the
bottleneck; if it is too high, the measurement methodology is suspect.)

**Status:** Not yet testable. Requires: boot, time model, measurement
infrastructure, and a method to instrument non-kernel sources (SMI counters,
performance counters).

### H3: Driver WCET watchdog containment

**Statement:** A per-driver WCET watchdog (Decision 011 in
`DECISIONS_KERNEL.md`) contains the impact of a misbehaving driver such that the
p999 of an unrelated interactive task is not affected by more than 10% when the
driver enters degraded mode, compared to a baseline where the driver is absent.

**Falsification criterion:** If the unrelated task's p999 degrades by more than
10% when the driver is marked unstable, H3 is falsified.

**Status:** Not yet testable. Requires: driver subsystem, watchdog
implementation, and measurement infrastructure.

### H4: Portability to deterministic hardware

**Statement:** The scheduler and time model, ported to ARM Cortex-M (no MMU, no
SMI, DWT cycle counter as time source), produce bounds that are *provable* under
static analysis, not merely observable, for a defined set of tasks.

**Falsification criterion:** If static analysis cannot bound the WCET of the
defined task set on Cortex-M within a factor of 2 of the observed WCET, H4 is
falsified.

**Status:** Deferred. Requires the x86_64 port to be stable first (Decision 012
in `DECISIONS_PROJECT.md`).

### H5 (exploratory): Threshold of kernel-attributable latency

**Statement:** *(to be written)*

**Falsification criterion:** *(to be written)*

**Status:** Exploratory. Not yet formulated.

---

## 4. Methodology

### 4.1 Time source and timestamping

Defined in Decision 010 in `DECISIONS_KERNEL.md`. Summary:

- TSC with invariant-TSC verification at boot, read via `RDTSCP`.
- HPET as fallback.
- APIC timer for periodic events only.

### 4.2 Instrumentation points

Defined in Decision 010 in `DECISIONS_KERNEL.md`. Summary:

- `irq_entry`, `task_resume`, `syscall_entry`, `syscall_return`.

### 4.3 Controlled conditions

All latency benchmarks are run under the following conditions, documented in
every result:

- CPU governor set to `performance`.
- Turbo boost disabled.
- SMT disabled (or explicitly noted if enabled).
- Critical tasks pinned to isolated cores (`isolcpus` equivalent in KinetOS).
- No other user workloads on the machine.
- Warm-up iterations discarded (first N runs).

Results obtained in QEMU are marked `emulated` and do not replace measurements
on real hardware. QEMU does not reproduce SMI, turbo boost, or DRAM refresh
behavior.

### 4.4 Sample size

- p99: minimum 10,000 samples.
- p999: minimum 100,000 samples.
- Runs with fewer samples are rejected.

### 4.5 Reporting

Every benchmark result reports:

- Time source used (TSC or HPET).
- Run configuration (CPU model, frequency, turbo state, SMT state, isolation).
- Sample count.
- p50, p99, p999, and jitter (`p999 - p50`).
- A column separating kernel-attributable from non-kernel-attributable latency,
  when instrumentable.

*(More detail on the attribution method to be written once measurement
infrastructure exists.)*

---

## 5. Literature

Works that inform the project. Entries marked *(to be read)* have not yet been
fully reviewed.

### 5.1 Real-time and deterministic kernels

- **QNX Neutrino** — commercial real-time OS; reference for priority-based
  scheduling and driver timeouts.
- **LITMUS^RT** — real-time extension to Linux; reference for measurement
  methodology.
- **PREEMPT_RT** — two-decade effort to make Linux deterministic; reference for
  the cost of retrofitting predictability onto a general-purpose kernel.
  *(to be read)*
- **seL4** — microkernel with formal WCET proofs; reference for what "provable
  bounds" requires. *(to be read)*
- **ARINC 653** — avionics standard for temporal partitioning; reference for
  the vocabulary of certifiable bounds.

### 5.2 Tail latency in distributed systems

- **Xu et al., "Characterizing Tail Latency in Datacenters"** — reference for
  the operational definition of p99/p999 and the argument that tail latency is
  the metric that matters in interactive systems.
- **Dean & Barroso, "The Tail at Scale"** — reference for why tail latency
  amplifies in fan-out systems. *(to be read)*

### 5.3 Schedulers and latency

- **CFS (Linux)** — baseline for comparison; optimizes fairness and average
  throughput.
- **AQUOSA (Linux, 2018)** — latency-oriented scheduler for Linux; closest
  prior work to KinetOS's scheduler goal. *(to be read)*
- **BFS / MuQSS (Con Kolivas)** — alternative Linux schedulers focused on
  interactivity; reference for trade-offs. *(to be read)*

### 5.4 Userspace network stacks

- **mTCP** — userspace TCP stack motivated by latency; reference for moving
  network out of the kernel core. *(to be read)*

### 5.5 Textbooks and references

- **Intel SDM Volumes 3A, 3B** — paging, TSC, HPET, APIC timer, SMI.
- **ARMv7-M Architecture Reference Manual** — Cortex-M memory model, MPU, DWT.
- **OSDev Wiki** — practical reference for x86_64 boot and paging.
- **xv6** — minimal teaching kernel; reference for code structure.

*(This section will be expanded as literature is reviewed. Each entry should
eventually include a one-paragraph summary of what it contributes to the
project and what it does not.)*

---

## 6. Falsification log

When a hypothesis is tested and falsified, the result is recorded here. A
falsified hypothesis is not a failure of the project; it is a result.

*(Empty. No hypothesis has been tested yet.)*

---

## 7. Open questions

Questions that are not yet formulated as hypotheses:

- How does KinetOS's scheduler behave under sustained overload (more runnable
  tasks than cores)?
- What is the cost, in latency, of the WCET watchdog itself?
- Can the time model be made portable to Cortex-M without a per-architecture
  abstraction that adds measurable overhead?
- How should the kernel report non-kernel-attributable latency to userspace
  without adding latency on the reporting path?

*(to be expanded)*

---

## 8. Revision history

- **2026-10-11** — Initial skeleton. Hypotheses H1–H4 stated; H5 placeholder.
  Literature section populated with references already cited in the Decisions,
  plus additions marked *(to be read)*.

**End of document.**