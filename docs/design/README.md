# Design Documents

This directory contains the architecture of KinetOS. Each document
decides one aspect of the system; together they define what the kernel
promises and what it does not.

Read in this order:

1. [execution-model.md](execution-model.md) — scheduling model, time,
   preemption, admission, deadline behavior.
2. [isolation-model.md](isolation-model.md) — temporal and spatial
   partitioning, fault containment.
3. [interrupt-model.md](interrupt-model.md) — threaded IRQs, scheduler
   outside interrupt context.
4. [memory-model.md](memory-model.md) — no demand paging, fixed pools,
   no shared memory.
5. [ipc-model.md](ipc-model.md) — synchronous IPC, priority ceiling,
   time bounds.
6. [certification.md](certification.md) — targets, boundary, traceability.

The contracts that bind code to guarantees live in
[`../contracts/`](../contracts/):

- [driver-contract.md](../contracts/driver-contract.md)
- [hal-contract.md](../contracts/hal-contract.md)
- [wcet-analysis.md](../contracts/wcet-analysis.md)

Design decisions that affect the project as a whole are recorded in
[`../DECISIONS_PROJECT.md`](../DECISIONS_PROJECT.md) and
[`../DECISIONS_KERNEL.md`](../DECISIONS_KERNEL.md).
