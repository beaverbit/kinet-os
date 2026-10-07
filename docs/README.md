# KinetOS Documentation

## Design

The architecture of the system, in reading order:

- [`design/execution-model.md`](design/execution-model.md)
- [`design/isolation-model.md`](design/isolation-model.md)
- [`design/interrupt-model.md`](design/interrupt-model.md)
- [`design/memory-model.md`](design/memory-model.md)
- [`design/ipc-model.md`](design/ipc-model.md)
- [`design/certification.md`](design/certification.md)
- [`design/README.md`](design/README.md) — index

## Contracts

The contracts that bind code to guarantees:

- [`contracts/driver-contract.md`](contracts/driver-contract.md)
- [`contracts/hal-contract.md`](contracts/hal-contract.md)
- [`contracts/wcet-analysis.md`](contracts/wcet-analysis.md)

## Decisions

Architecture Decision Records:

- [`DECISIONS_KERNEL.md`](DECISIONS_KERNEL.md)
- [`DECISIONS_PROJECT.md`](DECISIONS_PROJECT.md)
- [`COMMITS.md`](COMMITS.md) — commit convention
- [`ROADMAP.md`](ROADMAP.md)

## Planned (not yet written)

The following are planned but not yet created. They should be written
as the corresponding code is written, not before.

- `internals/boot.md` — boot process
- `internals/interrupts.md` — interrupt handling
- `internals/syscalls.md` — syscall interface
- `api/syscalls.md` — syscall reference
- `api/drivers.md` — driver model
- `latency/methodology.md` — how we measure
- `latency/benchmarks.md` — benchmarks
