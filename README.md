<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo-light.png">
    <img alt="KinetOS" src="assets/logo-light.png" width="600">
  </picture>
</p>

# KinetOS

A portable operating system for latency-critical workloads. KinetOS targets
**tail latency** (p99, p999) and **worst-case predictability** as primary
requirements, not as consequences of average-case design.

## What this means technically

KinetOS is built around three commitments:

1. **Tail latency is the metric.** Average throughput is secondary. A system
   with high throughput and unpredictable p999 fails the design goal.
2. **Worst-case is a requirement.** Bounds must be declared and provable, not
   observed post-hoc from benchmarks.
3. **Isolation is structural.** A timing fault in one component must not
   propagate to others.

These commitments constrain the architecture: the certifiable kernel is
minimal, drivers declare a WCET contract, filesystem and network stacks run
in isolated partitions, and no dynamic allocation is permitted on the
critical path.

## Non-goals

KinetOS is **not** a general-purpose operating system. It deliberately does
not promise:

- Throughput as a primary metric
- Fairness between workloads
- Compatibility with POSIX or Linux ABIs
- Support for demand paging on the critical path
- Portability pursued for its own sake

Any workload where worst-case predictability is a requirement is in scope.
Workloads where it is not are better served by general-purpose systems.

## Repository structure

- `core/` — the certifiable kernel. Scheduler, time, isolation, IPC.
- `platform/` — HAL and drivers, both under declared temporal contracts.
- `services/` — filesystem, network, userspace. Run in isolated partitions,
  outside the kernel.
- `lib/no-alloc/` — code safe for the critical path. No dynamic allocation.
- `lib/general/` — code that must **not** run in the kernel.
- `validation/` — proof of temporal guarantees: WCET analysis, adversarial
  load, chaos, conformance, benchmarks.
- `configs/` — build profiles: `hard-rt`, `soft-rt`, `minimal`.
- `docs/design/` — the architecture. Start with `execution-model.md`.
- `docs/contracts/` — the contracts binding code to guarantees.

## Documentation

See [`docs/`](docs/) for the full index and [`docs/ROADMAP.md`](docs/ROADMAP.md)
for the roadmap.

The architecture is specified in `docs/design/`:

- [`execution-model.md`](docs/design/execution-model.md) — time model, preemption, admission
- [`isolation-model.md`](docs/design/isolation-model.md) — temporal and spatial partitioning
- [`ipc-model.md`](docs/design/ipc-model.md) — semantics, priority inversion, time bounds
- [`memory-model.md`](docs/design/memory-model.md) — allocation, paging, protection
- [`interrupt-model.md`](docs/design/interrupt-model.md) — delivery latency, threading
- [`certification.md`](docs/design/certification.md) — targets and traceability

The contracts in `docs/contracts/` define what code must declare to be accepted:

- [`driver-contract.md`](docs/contracts/driver-contract.md)
- [`hal-contract.md`](docs/contracts/hal-contract.md)
- [`wcet-analysis.md`](docs/contracts/wcet-analysis.md)

## License

GPLv2 — see [LICENSE](LICENSE).
