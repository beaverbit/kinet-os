# Isolation Model

## Status

Proposed. This document defines how temporal and spatial isolation are
enforced. It depends on `docs/design/execution-model.md`.

## Decision

Isolation has two independent dimensions:

1. **Temporal isolation** — enforced by the partition scheduler. A partition
   can only execute during its assigned window. A partition that overruns
   its budget cannot steal time from another.
2. **Spatial isolation** — enforced by hardware protection (MMU/MPU) and by
   the kernel's memory model. A partition cannot read or write memory that
   is not assigned to it.

Both dimensions are structural: they are enforced by hardware and by the
kernel, not by convention or code review.

## Temporal isolation

Each partition is defined by a pair `(budget, period)`:

- `budget` — nanoseconds of CPU time the partition may consume per period.
- `period` — length of the partition's scheduling cycle in nanoseconds.

The scheduler guarantees `budget` out of every `period`, subject to the
total utilization constraint from `docs/design/execution-model.md`.

### Budget exhaustion

If a partition consumes its full budget before its window ends:

1. The partition is descheduled immediately.
2. The scheduler moves to the next partition in the cycle.
3. The event is recorded in the partition's fault channel.
4. The partition is not replenished until its next period.

This guarantees that no partition can extend its window by misbehaving.

### Priority between partitions

Partitions are scheduled by a fixed cycle (round-robin over the partition
list) defined at configuration time. There is no dynamic priority between
partitions. Criticality is expressed by the budget and period values, not
by dynamic priority.

*(Open question: whether criticality-based replenishment is needed. See
"Open questions" below.)*

## Spatial isolation

Each partition runs in its own address space. Hardware protection is
mandatory:

- **Tier 1 (x86_64, aarch64):** MMU-based paging. Each partition has its
  own page table root. Kernel memory is not mapped in partition address
  spaces.
- **Tier 2/3:** MPU-based region protection where MMU is unavailable.
  The exact mechanism is architecture-specific and declared in
  `platform/hal/<arch>/`.

A partition cannot:

- Access memory outside its assigned regions.
- Execute code outside its assigned text regions.
- Access device MMIO regions it does not own.
- Modify its own page tables or MPU configuration.

Any attempt triggers a hardware fault. The fault is routed to the
partition's fault handler, not to the kernel.

## Fault propagation

A fault in one partition must not affect any other:

- **Temporal fault** (budget overrun): handled by the partition scheduler,
  as described above.
- **Spatial fault** (memory access violation): handled by the partition's
  fault handler. The kernel does not attempt to recover the partition.
- **Driver fault**: if a `partitioned` driver exceeds its declared WCET,
  the partition that hosts it is suspended. See
  `docs/contracts/driver-contract.md`.
- **Certified kernel fault**: not isolated. A fault in `core/` is a system
  fault by definition. This is why `core/` must remain minimal and provable.

## Certifiable kernel vs. partitioned components

| Component              | Runs in         | Isolation        |
| ---------------------- | --------------- | ---------------- |
| `core/`                | kernel          | none (by design) |
| `platform/hal/`        | kernel          | none (by design) |
| `platform/drivers/certified/` | kernel   | none (by design) |
| `platform/drivers/partitioned/` | partition | full     |
| `services/fs/`         | partition       | full             |
| `services/net/`        | partition       | full             |
| `services/userspace/`  | partition       | full             |

Components in the kernel are trusted. Components in partitions are not.
The boundary is enforced by hardware and by the partition scheduler.

## Configuration

Partitions are defined in `configs/<profile>/partitions.toml`:

```toml
[[partition]]
name = "control"
budget_ns = 2000000
period_ns = 10000000
memory_regions = ["0x40000000-0x4000FFFF"]
devices = ["timer0"]

[[partition]]
name = "network"
budget_ns = 3000000
period_ns = 10000000
memory_regions = ["0x50000000-0x500FFFFF"]
devices = ["eth0"]
```

Partitions are not created at runtime. The configuration is fixed at
build time and validated by the build system.

## Open questions

- Criticality-based replenishment: should a high-criticality partition
  receive leftover budget from a low-criticality one? This is a known
  approach in mixed-criticality systems, but it complicates certification.
- Shared memory between partitions: allowed? If yes, how is cache
  coherency handled? If no, all IPC is copy-based (see
  `docs/design/ipc-model.md`).
- Fault handler interface: is there a standard interface, or does each
  partition define its own?
