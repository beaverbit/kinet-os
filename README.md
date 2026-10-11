<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo-light.png">
    <img alt="KinetOS" src="assets/logo-light.png" width="600">
  </picture>
</p>


# KinetOS

A research operating system for latency-critical workloads. KinetOS treats
**tail latency** (p99, p999) and **worst-case predictability** as primary
requirements, not as consequences of average-case design.

KinetOS is a **research project**, not a product. It does not aim for
commercial adoption, POSIX compatibility, or general-purpose use. The goal is
to understand, measure, and document the sources of latency in a kernel
designed from scratch around predictability.

---

## Technical commitments

1. **Tail latency is the metric.** Average throughput is secondary. A system
   with high throughput and unpredictable p999 does not meet the design goal.

2. **Bounds are declared, observable, and bounded by watchdog.** Each subsystem
   declares a latency budget. Benchmarks measure actual latency against that
   budget under controlled conditions (pinned frequency, turbo disabled, core
   isolation). Drivers declare a WCET per operation, enforced by a per-driver
   watchdog. Bounds are **not** claimed to be provable on x86_64 commodity
   hardware — see "What we do not promise" below.

3. **Isolation is structural.** A timing fault in one component does not
   propagate to others. Device drivers run in kernel space but are contained by
   the WCET watchdog. Filesystem and network stacks run outside the kernel
   core, in a privileged service layer that cannot block the scheduler or the
   memory subsystem on their critical paths.

These commitments constrain the architecture. The kernel is minimal; drivers
declare a WCET; filesystem and network run outside the kernel core; no dynamic
allocation is permitted on the critical path.

---

## How latency is measured

Latency is defined operationally as the interval between explicit kernel
instrumentation points:

- **Wakeup latency:** from interrupt handler entry (`irq_entry`) to the first
  instruction of the resumed task in userspace (`task_resume`).
- **Syscall latency:** from `syscall_entry` to `syscall_return`.
- **Interrupt-to-task latency:** from `irq_entry` to the first instruction of
  the task unblocked by the interrupt.

p99 is the 99th percentile of these samples over a run with at least 10,000
samples. Jitter is defined as `p999 - p50` in the same run.

Time source: TSC with invariant-TSC verification at boot, read via `RDTSCP`
(or `LFENCE; RDTSC` when `RDTSCP` is unavailable). HPET as fallback when TSC
invariance cannot be confirmed. The APIC timer is used only to generate
periodic events, not for measurement.

For the full methodology, see Decision 010 in `docs/DECISIONS_KERNEL.md`.

---

## What we do not promise

KinetOS is not a general-purpose operating system. It deliberately does not
promise:

- **Throughput as a primary metric.** A workload optimized for average
  throughput may perform worse on KinetOS than on Linux.
- **Fairness between workloads.** The scheduler prioritizes interactive tasks
  and critical workloads; batch workloads may starve under sustained load.
- **POSIX or Linux ABI compatibility.** System calls, file APIs, and process
  semantics are KinetOS-specific.
- **Demand paging on the critical path.** Memory is pre-allocated for tasks on
  the critical path.
- **Portability for its own sake.** x86_64 is the initial target; ARM Cortex-M
  is a deferred secondary target (Decision 012 in `docs/DECISIONS_PROJECT.md`).
- **Provable bounds on x86_64 commodity hardware.** Sources of latency outside
  kernel control — SMI, turbo boost, DRAM refresh, TLB shootdown, cache
  behavior, and host interference under QEMU — are documented, measured, and
  reported separately, but not eliminated. "Provable bounds" is a vocabulary
  reserved for deterministic hardware (e.g., ARM Cortex-M), if and when that
  target is pursued.

Any workload where worst-case predictability is a requirement is in scope for
research. Any workload where average throughput or fairness is the primary
concern is not.

---

## Research scope

KinetOS is a research project. Its scope is defined by questions, not by
features:

- Can a scheduler designed around tail latency (rather than fairness) reduce
  p999 relative to CFS on interactive workloads?
- What fraction of observed p999 is attributable to the kernel, and what
  fraction is attributable to hardware and firmware outside kernel control?
- Can a per-driver WCET watchdog contain the impact of a misbehaving driver
  without kernel-space abort?
- On deterministic hardware (ARM Cortex-M), does the same scheduler design
  produce bounds that are provable, not just observable?

Hipóteses, methodology, and falsification criteria will be documented in
`docs/RESEARCH.md` as the project matures. The current phase is infrastructure:
boot, memory, time model, and measurement, before the scheduler is validated.

---

## Roadmap

- [x] Initial structure
- [x] Boot (Limine)
- [ ] VGA text mode
- [ ] GDT / IDT
- [ ] Physical and virtual memory
- [ ] Time model (TSC, invariant TSC detection, timestamp API)
- [ ] Latency measurement infrastructure (tracepoints, ring buffer, userspace
      reader)
- [ ] Scheduler (tail-latency oriented)
- [ ] Syscalls
- [ ] Userspace
- [ ] Drivers (with WCET contract)
- [ ] Benchmarks (latency, jitter, p99/p999)

See `docs/ROADMAP.md` for the detailed roadmap with notes.

---

## Documentation

- `docs/DECISIONS_KERNEL.md` — kernel architecture decisions (stack, scope,
  architecture, memory, scheduler, drivers, timing, measurement, bounds).
- `docs/DECISIONS_PROJECT.md` — project process decisions (license, development
  model, tooling, code structure, future phases).
- `docs/ROADMAP.md` — development roadmap.
- `docs/COMMITS.md` — commit convention.
- `docs/RESEARCH.md` — research hypotheses and methodology (to be written).

Writing conventions:

- Use Markdown.
- Every design decision that touches latency must include the reasoning and, if
  possible, numbers.
- Keep diagrams in Mermaid when possible (renders on GitHub).

---

## Building

Requirements:

- `gcc` or `clang` with cross-compilation support
- `nasm` (for x86_64 boot stubs)
- `qemu-system-x86_64`
- `gdb` (for kernel debugging)
- `make`

```sh
make defconfig
make
make run
```

Testing

· make test — unit tests
· make test-integration — boot in QEMU
· make benchmark-latency — latency benchmarks (p99/p999, jitter)

Latency benchmarks require a controlled environment: CPU frequency pinned,
turbo disabled, and no other workloads on the machine. Results obtained in
QEMU are marked "emulated" and do not replace measurements on real hardware.

---

Contributing

KinetOS is a research project. Contributions are welcome, but the bar for
changes that touch the critical path (kernel/sched/, kernel/irq/,
kernel/time/, arch/*/interrupts/, arch/*/timers/) is high: every such
change must include before/after latency measurements in the PR description.

Any change that improves average throughput but worsens worst-case latency
will be rejected.

See docs/CONTRIBUTING.md and docs/COMMITS.md for details.

---

Security

See docs/SECURITY.md for the vulnerability reporting policy.

---

License

GPLv2 — see LICENSE.