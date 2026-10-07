# Execution Model

## Status

Proposed. This document is the anchor for all scheduling, IPC, memory, and
interrupt decisions. Nothing in `core/` may be implemented before this is
accepted.

## Decision

KinetOS uses **hierarchical scheduling**:

1. **Temporal partitions** at the top level, ARINC 653-style. Each partition
   receives a budget `B` out of every period `P`. The partition executes only
   during its window, regardless of workload.
2. **Fixed-priority preemptive scheduling (rate-monotonic)** inside each
   partition. Priorities are assigned by period: shorter period, higher priority.

## Rationale

- Temporal partitioning provides the isolation guarantee the README promises:
  a partition that overruns its budget cannot steal time from others.
- Rate-monotonic is analysable and certifiable. Utilization bound (Liu & Layland)
  is a sufficient condition for schedulability; exact analysis is available
  via response-time analysis.
- EDF is rejected: optimal in utilization, but unstable under overload and
  difficult to certify for hard real-time avionics/medical standards.

## Formal properties

- A partition with budget `B` and period `P` receives exactly `B` out of
  every `P`, provided the total partition utilization `Σ(Bᵢ/Pᵢ) ≤ 1`.
- Within a partition, if the task set utilization `U ≤ n(2^(1/n) − 1)` for
  `n` tasks under rate-monotonic, all deadlines are met.
- WCET of any code path in `core/sched/` is bounded and declared.

## Assumptions

- Tasks are periodic or sporadic with known minimum inter-arrival times.
- All task WCETs are declared (see `docs/contracts/wcet-analysis.md`).
- Preemption is enabled at all points except inside declared critical sections.
- All partitions are known at configuration time. Dynamic partition creation
  is not supported.

## Admission

A partition is admitted at build time only if the total partition utilization
does not exceed 1, using the config in `configs/<profile>/`.

A task is admitted into a partition only if the resulting task set remains
schedulable under rate-monotonic analysis. Admission is checked statically
at build time; there is no runtime admission.

## Deadline violations

- **Partition budget exhausted early:** the partition is suspended until the
  next replenishment. The event is logged to the partition's fault channel.
- **Task misses a deadline:** the kernel does not abort the task by default.
  The event is recorded; the partition decides whether to continue or restart.
  (Configurable per profile; `hard-rt` may enforce abort-on-miss.)
- **Total partition utilization > 1:** this is a build-time error. Runtime
  detection is a fatal kernel fault.

## Preemption

- The partition scheduler preempts at window boundaries. No partition may
  run outside its window.
- Within a partition, the scheduler preempts at any instruction boundary
  except inside declared critical sections (`core/sync/`).
- Interrupt handlers are threaded (see `docs/design/interrupt-model.md`).
  Top-half handlers are minimal, bounded, and never call the scheduler.

## Non-goals

- Fairness between partitions is not provided.
- EDF is not used, for certification reasons.
- Dynamic task creation at runtime is not supported.
- Soft real-time within a partition is not a target.

## Open questions

- Priority assignment within a partition: rate-monotonic, deadline-monotonic,
  or explicit priority declaration?
- Partition replenishment policy: fixed-priority, round-robin, or
  criticality-based?
- Cross-partition IPC latency bound: see `docs/design/ipc-model.md`.
