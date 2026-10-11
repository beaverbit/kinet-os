# Roadmap

Current status of KinetOS development. Checkboxes are marked as milestones are
reached.

Each phase lists the benchmark associated with it (Decision 002 in
`DECISIONS_PROJECT.md`) and the Decisions that govern it. A phase is not
considered complete until its benchmark exists and runs — even if the benchmark
only reports "not yet measurable".

For architectural context, see `DECISIONS_KERNEL.md` and
`DECISIONS_PROJECT.md`. For research hypotheses and measurement methodology, see
`RESEARCH.md`.

---

## Phase 1 — Initial structure

**Status:** Done

- [x] Repository layout (`boot/`, `kernel/`, `services/`, `userspace/`, `docs/`,
      `scripts/`)
- [x] Makefile with targets: `defconfig`, `build`, `run`, `debug`, `clean`
- [x] `docs/` with Decisions, Roadmap, Commit convention
- [x] License (GPLv2), Code of Conduct, Contributing, Security policy

**Benchmark:** none (infrastructure phase).

**Decisions:** 003, 004 (project).

---

## Phase 2 — Boot

**Status:** In progress

- [ ] Limine integration
- [ ] Kernel loaded at higher-half virtual address
- [ ] Linker script with correct section placement
- [ ] Early serial output (COM1) for bring-up diagnostics
- [ ] `kmain` entry point reached from Limine

**Benchmark:** none (boot is not on the latency-critical path, but boot time is
recorded for regression detection).

**Decisions:** 005 (kernel), 005 (project).

---

## Phase 3 — VGA text mode

**Status:** Not started

- [ ] VGA text buffer driver (80x25)
- [ ] `kprintf` with basic formatting
- [ ] Panic handler that prints to VGA and serial

**Benchmark:** none.

**Decisions:** 008 (kernel, driver in kernel space).

**Note:** VGA text mode is for early bring-up only. It will be replaced by a
proper framebuffer or serial console later, but is sufficient to debug memory
and scheduler work.

---

## Phase 4 — GDT / IDT

**Status:** Not started

- [ ] GDT with kernel and user segments
- [ ] TSS for interrupt stack
- [ ] IDT with handlers for exceptions and IRQs
- [ ] PIC remapping (or APIC setup — decide before Phase 6)

**Benchmark:** none.

**Decisions:** 004, 006 (kernel).

**Note:** The choice between PIC and APIC affects the time model (Phase 6).
APIC is the correct choice for a latency-focused kernel; PIC is legacy. Decide
before Phase 6.

---

## Phase 5 — Physical and virtual memory

**Status:** Not started

- [ ] Physical memory manager (bitmap or buddy allocator)
- [ ] 4-level paging (PML4, PDPT, PD, PT)
- [ ] Higher-half kernel mapping
- [ ] Huge pages (2 MB) for kernel text and data
- [ ] Heap allocator for kernel (`kmalloc`/`kfree`)
- [ ] Static allocation for critical-path structures (no `kmalloc` on the
      critical path — Decision 009 in `DECISIONS_KERNEL.md`)

**Benchmark:** `bench_mm_alloc` — measures `kmalloc`/`kfree` p50, p99, p999 for
a set of standard sizes. This benchmark exists even though MM is not the primary
target, because allocation latency on the critical path would invalidate
scheduler measurements later.

**Decisions:** 006 (kernel), 009 (kernel).

---

## Phase 6 — Time model

**Status:** Not started

- [ ] TSC invariant-TSC verification at boot
- [ ] Timestamp API: `ktime_now()` returning nanoseconds, backed by `RDTSCP`
- [ ] HPET fallback path when TSC is not invariant
- [ ] APIC timer (or PIT) for periodic events
- [ ] Documentation of the time source in `docs/DECISIONS_KERNEL.md`
      (Decision 010)

**Benchmark:** `bench_time_source` — measures:
- Read latency of `ktime_now()` (should be tens of cycles, not hundreds).
- Drift between TSC and HPET over a fixed interval.
- Invariant-TSC detection result on the target hardware.

This benchmark is a prerequisite for every latency benchmark that follows.

**Decisions:** 010 (kernel).

**Note:** Without this phase, no latency number produced by the project is
meaningful. This phase blocks the scheduler phase.

---

## Phase 7 — Latency measurement infrastructure

**Status:** Not started

- [ ] Instrumentation points: `irq_entry`, `task_resume`, `syscall_entry`,
      `syscall_return`
- [ ] Per-CPU ring buffer for samples (lock-free on the producer side)
- [ ] Userspace reader via a character device or shared memory
- [ ] `scripts/bench-latency.sh` that configures the environment (CPU governor,
      turbo, isolation), runs the workload, and produces a report
- [ ] Sample count enforcement (10,000 for p99, 100,000 for p999 — Decision 010
      in `DECISIONS_KERNEL.md`)

**Benchmark:** `bench_irq_latency` — measures interrupt-to-handler-entry latency
on an idle system. This is the simplest possible measurement and validates that
the infrastructure itself works before the scheduler exists.

**Decisions:** 010 (kernel), 011 (kernel, for the driver side, later).

**Note:** This phase produces no user-visible feature. Its only output is the
ability to measure. Skipping it is the most common failure mode in latency
projects.

---

## Phase 8 — Scheduler (tail-latency oriented)

**Status:** Not started

- [ ] Run queue design (per-CPU, priority-based, no CFS-style fairness)
- [ ] Fast preemption path
- [ ] CPU isolation support (`isolcpus` equivalent)
- [ ] Context switch in assembly (with TSC timestamping at boundaries)
- [ ] Integration with the time model (Phase 6) and measurement infrastructure
      (Phase 7)

**Benchmark:** `bench_sched_wakeup` — measures wakeup latency p50, p99, p999,
and jitter for an interactive workload. This is the primary benchmark of the
project. It tests hypothesis H1 in `RESEARCH.md`.

**Decisions:** 007 (kernel), 009 (kernel).

**Note:** H1 (scheduler design and tail latency) can only be tested after this
phase. The baseline (CFS) must be measured on the same hardware under the same
controlled conditions, not taken from literature.

---

## Phase 9 — Syscalls

**Status:** Not started

- [ ] `syscall`/`sysret` entry and exit paths
- [ ] Minimal syscall table (read, write, exit, mmap, futex)
- [ ] Per-syscall instrumentation (`syscall_entry`, `syscall_return` —
      Decision 010 in `DECISIONS_KERNEL.md`)

**Benchmark:** `bench_syscall` — measures syscall latency p50, p99, p999 for a
set of hot syscalls (`read` on a pipe, `futex` wake, `mmap`).

**Decisions:** 010 (kernel).

---

## Phase 10 — Userspace

**Status:** Not started

- [ ] ELF loader
- [ ] Minimal libc (or static linking with a freestanding libc subset)
- [ ] `init` process that runs the latency benchmark suite
- [ ] `bench_latency` userspace tool that reads ring buffers (Phase 7) and
      produces reports

**Benchmark:** `bench_end_to_end` — measures wakeup latency from an interrupt
to a userspace task, including the transition. This is the number that matters
for real workloads.

**Decisions:** 004 (kernel), 008 (kernel).

---

## Phase 11 — Drivers (with WCET contract)

**Status:** Not started

- [ ] Driver registration structure with WCET fields per operation
      (Decision 011 in `DECISIONS_KERNEL.md`)
- [ ] Per-driver watchdog using the time model (Phase 6)
- [ ] Violation buffer and diagnostic interface
- [ ] Degraded-mode logic (reject new calls to unstable driver with `-EBUSY`)
- [ ] First real driver (serial, timer, or block device — decide based on what
      the benchmark suite needs)

**Benchmark:** `bench_driver_wcet` — measures:
- Overhead of the watchdog itself on a well-behaved driver.
- p999 of an unrelated interactive task when a driver is deliberately made to
  violate its WCET. This tests hypothesis H3 in `RESEARCH.md`.

**Decisions:** 008 (kernel), 011 (kernel).

---

## Phase 12 — Benchmarks (consolidation)

**Status:** Not started

- [ ] `make benchmark-latency` runs the full suite and produces a report
- [ ] Report includes: time source, configuration, sample count, p50, p99,
      p999, jitter
- [ ] Report separates kernel-attributable from non-kernel-attributable latency
      (when instrumentable — tests hypothesis H2 in `RESEARCH.md`)
- [ ] Results stored under `validation/` with a version tag

**Benchmark:** the suite itself.

**Decisions:** 002 (project), 010 (kernel), 012 (kernel).

---

## Phase 13 — Deferred (future)

Phases not yet scheduled. Kept here so the roadmap reflects the full project
intent without committing to a timeline.

- [ ] **Filesystem and network service layer** — outside the kernel core
      (Decision 008 in `DECISIONS_KERNEL.md`).
- [ ] **ARM Cortex-M port** — Decision 012 in `DECISIONS_PROJECT.md`. Requires
      HAL abstraction and a portable time model.
- [ ] **Embedded mode** (`make embedded`, single binary, no userspace) —
      Decision 013 in `DECISIONS_PROJECT.md`.
- [ ] **Industrial and IoT protocols** (MQTT, Modbus, CAN, CoAP, OPC-UA) —
      Decision 014 in `DECISIONS_PROJECT.md`.
- [ ] **CI/CD** — Decision 011 in `DECISIONS_PROJECT.md`. When introduced,
      latency benchmarks must run on dedicated hardware, not shared runners.
- [ ] **`docs/RESEARCH.md` hypotheses H4 and H5** — H4 depends on the
      Cortex-M port; H5 is exploratory.

---

## Notes on environment

- Development and early testing happen in **QEMU** (Decision 005 in
  `DECISIONS_PROJECT.md`).
- Latency benchmarks run in QEMU are marked `emulated` and do not replace
  measurements on real hardware. QEMU does not reproduce SMI, turbo boost, or
  DRAM refresh.
- Real-hardware testing happens at milestones, with the environment documented
  in the benchmark report (CPU model, frequency, turbo state, SMT state,
  isolation).
- The first real-hardware milestone is Phase 8 (scheduler). Before that, QEMU
  is sufficient for correctness, not for latency numbers.

---

## Summary table

| Phase | Name | Benchmark | Decision (kernel) | Blocks |
|---|---|---|---|---|
| 1 | Initial structure | — | — | — |
| 2 | Boot | — | 005 | Phase 3+ |
| 3 | VGA text mode | — | 008 | Phase 4+ |
| 4 | GDT / IDT | — | 004, 006 | Phase 5+ |
| 5 | Physical and virtual memory | `bench_mm_alloc` | 006, 009 | Phase 8 |
| 6 | Time model | `bench_time_source` | 010 | **Phase 7, 8, 9** |
| 7 | Latency measurement infra | `bench_irq_latency` | 010, 011 | **Phase 8** |
| 8 | Scheduler | `bench_sched_wakeup` | 007, 009 | Phase 9+ |
| 9 | Syscalls | `bench_syscall` | 010 | Phase 10 |
| 10 | Userspace | `bench_end_to_end` | 004, 008 | Phase 11+ |
| 11 | Drivers (WCET contract) | `bench_driver_wcet` | 008, 011 | Phase 12 |
| 12 | Benchmarks (consolidation) | suite | 002 (project), 010, 012 | — |
| 13 | Deferred | — | 012–014 (project) | — |

**End of document.**