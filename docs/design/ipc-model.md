# IPC Model

## Status

Proposed. This document defines the semantics, timing bounds, and failure
behavior of inter-process communication. It depends on
`docs/design/execution-model.md`, `docs/design/isolation-model.md`, and
`docs/design/memory-model.md`.

## Decision

KinetOS provides **two IPC mechanisms**, one per scope:

1. **Cross-partition IPC** — synchronous, copy-based, with a declared
   deadline. Between partitions.
2. **Intra-partition IPC** — synchronous, zero-copy, with priority
   inheritance. Between threads of the same partition.

Both are synchronous. Asynchronous messaging (queues, mailboxes) is not
provided.

## Rationale

- Synchronous IPC makes the timing of a communication boundable. An
  asynchronous queue has unbounded backlog; the receiver's latency depends
  on the queue depth, which is not bounded by construction.
- Copy-based cross-partition IPC is a consequence of no shared memory
  (`docs/design/memory-model.md`). The copy cost is bounded and declared.
- Priority inheritance avoids unbounded priority inversion, which is the
  classic source of tail latency in IPC-heavy systems.

## Cross-partition IPC

### Semantics

A cross-partition send is a **rendezvous**:

1. Sender calls `ipc_send(dest_partition, message, deadline_ns)`.
2. The kernel copies the message into a per-partition inbox slot.
3. Sender blocks until the receiver calls `ipc_recv` and the message is
   acknowledged.
4. Sender returns.

If `deadline_ns` elapses before the rendezvous completes:

- The send is aborted.
- The message is discarded.
- The sender receives `IPC_DEADLINE_MISSED`.
- The event is recorded in both partitions' fault channels.

The receiver side:

1. Receiver calls `ipc_recv(inbox, deadline_ns)`.
2. If a message is pending, it is copied into the receiver's buffer and
   the sender is woken.
3. If no message is pending, the receiver blocks until its own deadline.

### Message size

The maximum message size is declared at configuration time:

```toml
[[ipc_channel]]
from = "control"
to = "network"
max_message_bytes = 256
```

A message larger than `max_message_bytes` is rejected at compile time if
statically known, or at runtime with `IPC_MESSAGE_TOO_LARGE`.

The copy cost is bounded by `max_message_bytes` and the reference
platform's memory bandwidth. This bound is declared in
`docs/contracts/wcet-analysis.md`.

### Deadline

Every cross-partition IPC operation takes an explicit `deadline_ns`. There
is no default deadline. A call without a deadline is a compile error.

A rendezvous that exceeds the declared deadline is a fault. The exact
behavior (log / abort sender / abort both / escalate to partition fault
handler) is profile-specific:

- `hard-rt`: abort both, record the event.
- `soft-rt`: abort sender, receiver continues.
- `minimal`: log only.

### Channels

IPC channels are declared at build time, not created at runtime:

```toml
[[ipc_channel]]
from = "control"
to = "network"
max_message_bytes = 256
max_pending = 1
```

`max_pending` is always 1. There is no message queue. A send when a
message is already pending blocks until the previous one is received or
the deadline expires.

This is deliberate: a bounded channel with depth 1 makes latency analysis
tractable. Queue depth > 1 introduces head-of-line blocking and defeats
the tail-latency goal.

## Intra-partition IPC

### Semantics

Within a partition, threads communicate through:

- **Mutex** — with priority inheritance.
- **Condition variable** — with a deadline.
- **Zero-copy message** — passing a pointer to a shared buffer within the
  partition's address space.

No copy is involved. The cost is a pointer transfer plus the cost of the
synchronization primitive.

### Priority inheritance

Every mutex declares its ceiling priority (the highest priority of any
thread that may acquire it) at configuration time. The kernel enforces:

- A thread holding a mutex runs at the ceiling priority until it releases.
- The ceiling is declared, not computed at runtime.
- A thread that acquires a mutex above its own priority is a configuration
  error, caught at build time.

This is the **priority ceiling protocol** (PCP), not priority inheritance
(PI). PCP has stronger properties (no deadlock, no unbounded inversion)
and is easier to analyze. PI is not supported.

### Deadlines on blocking primitives

`mutex_lock` and `cond_wait` accept a `deadline_ns`. A thread that blocks
past its deadline is woken with `ETIMEDOUT`. It is the caller's
responsibility to handle this; the kernel does not abort.

## No asynchronous IPC

Asynchronous messaging (mailboxes, queues, event channels) is not
supported. Every IPC operation blocks, by design. A thread that needs
to continue working while waiting uses a separate thread.

This is a deliberate constraint. Asynchronous IPC has a place in
throughput-oriented systems; it is incompatible with bounded tail
latency.

## Time bounds

The maximum latency of every IPC path is declared:

| Path                          | Bound source                                  |
| ----------------------------- | --------------------------------------------- |
| Cross-partition send          | `max_message_bytes` + scheduler window       |
| Cross-partition receive       | Partition window + copy cost                 |
| Intra-partition mutex acquire | Ceiling priority + critical section WCET     |
| Intra-partition message       | Pointer transfer cost                        |

These bounds are verified in `validation/wcet/` and compared against
declarations.

## Interaction with scheduling

- A blocked cross-partition sender does not consume its partition's budget
  while blocked. The budget is paused for the duration of the block.
- A blocked receiver in partition A does not prevent partition B from
  running. The two partitions are scheduled independently.
- Priority inheritance is confined to a partition. There is no
  cross-partition priority inheritance.

## Non-goals

- Asynchronous message queues are not supported.
- Shared memory between partitions is not supported.
- Cross-partition priority inheritance is not supported.
- Dynamic IPC channel creation is not supported. Channels are declared
  at configuration time.
- Broadcast or multicast IPC is not supported.

## Open questions

- Should the deadline be absolute or relative? Absolute is easier to
  compose; relative is easier to use. The current proposal is relative
  (`deadline_ns` is a timeout), but absolute deadlines are more common in
  real-time systems.
- How is the reference platform's memory bandwidth declared? Per arch?
  Per configuration? This affects the copy cost bound.
- What happens when a partition is suspended (budget exhausted) while it
  has a pending IPC message? The message is not delivered until
  replenishment. Should the sender be notified?
