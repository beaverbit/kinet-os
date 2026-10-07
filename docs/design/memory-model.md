# Memory Model

## Status

Proposed. This document defines how memory is allocated, protected, and
reclaimed. It depends on `docs/design/execution-model.md` and
`docs/design/isolation-model.md`.

## Decision

Memory is managed in three distinct regions with different rules:

1. **Kernel memory** — statically allocated at build time. No dynamic
   allocation in the kernel after boot.
2. **Partition memory** — pre-assigned regions per partition, fixed at
   configuration time. Each partition has its own pools.
3. **Shared memory** — not supported. All cross-partition communication
   is copy-based. See `docs/design/ipc-model.md`.

Dynamic paging is **not** supported on the critical path. All memory used
by `core/` and by `certified` drivers is pre-faulted and pinned.

## Rationale

- Demand paging introduces page faults, which introduce unbounded latency.
  A page fault during a real-time operation is a deadline miss.
- Dynamic allocation in the kernel introduces non-deterministic latency
  and the possibility of failure (out of memory) at a point where failure
  is not recoverable.
- Fixed pools per partition make memory consumption provable and bounded.

## Kernel memory

Kernel memory is allocated once, at boot, from a static region. After
boot:

- No new pages are mapped.
- No new physical frames are allocated.
- No dynamic data structures grow.

All kernel data structures are either:

- **Static** — declared at compile time, sized by configuration.
- **Bounded** — allocated from a fixed-size pool at boot, never beyond.

`core/` does not call into an allocator. `lib/no-alloc/` is the only
library permitted in the kernel, and it contains no allocation functions.

## Partition memory

Each partition has an assigned set of memory regions, declared in
`configs/<profile>/partitions.toml`:

```toml
[[partition]]
name = "control"
memory_regions = ["0x40000000-0x4000FFFF"]
heap_pool_bytes = 65536
stack_bytes = 16384
```

The partition's memory is divided into:

- **Text** — read-only, executable. Contains the partition's code.
- **Data** — read-write, initialized.
- **BSS** — read-write, zeroed at partition start.
- **Stack** — per-thread, fixed size, declared in configuration.
- **Heap** — fixed pool, pre-allocated. The partition may allocate from
  it using a bounded allocator.

The heap allocator available to partitions is a **fixed-size block
allocator**. Variable-size allocation is not supported. A partition that
needs a different size declares a different pool.

## Shared memory

Shared memory between partitions is **not supported**. Reasons:

- Cache coherency across partitions introduces latency that is hard to
  bound.
- Shared mutable state between partitions violates spatial isolation.
- It complicates the WCET analysis of any code that touches shared data.

All cross-partition communication is copy-based, through IPC. See
`docs/design/ipc-model.md`.

Within a partition, threads share memory normally. The partition is the
unit of isolation.

## Protection

Protection is enforced by hardware:

- **x86_64, aarch64:** MMU with per-partition page tables. Kernel memory
  is not mapped in partition address spaces.
- **riscv64:** PMP (Physical Memory Protection) regions where MMU is
  unavailable.

A partition cannot:

- Read or write memory outside its assigned regions.
- Execute code from writable memory (W^X is enforced).
- Map new pages at runtime. The page table is fixed at partition start.
- Modify its own page tables.

Any violation triggers a hardware fault, routed to the partition's fault
handler. The kernel does not attempt to recover.

## No demand paging

Demand paging is not available to any partition. All memory a partition
will use is:

- Mapped at partition start.
- Backed by physical frames assigned at configuration time.
- Pinned for the partition's lifetime.

This is a hard requirement of the execution model. A page fault during a
real-time operation is a deadline miss, which is not recoverable.

## Swapping

Swapping is not supported. The system assumes all memory is resident.

## Allocation on the critical path

Inside `core/` and inside `certified` drivers:

- No dynamic allocation, ever.
- All buffers are pre-allocated at boot.
- All data structures are fixed-size.

Inside a partition's bottom-half handlers:

- Allocation is permitted from the partition's fixed pool.
- The allocation operation's WCET is declared and bounded.
- Allocation failure is a partition fault, not a kernel fault.

Inside user-space code in a partition:

- Allocation from the partition's fixed-size block allocator.
- No `mmap`-style operations. Memory is mapped at partition start.

## Non-goals

- Virtual memory as a general-purpose abstraction (overcommit, demand
  paging, swapping) is not provided.
- `mmap` and similar interfaces are not supported.
- Memory overcommit is not supported.
- Copy-on-write is not supported.

## Open questions

- Should partitions be allowed to release memory back to their pool, or
  is memory assigned once at partition start?
- Should there be a system-wide emergency pool that a partition can draw
  from when its own pool is exhausted? If yes, how is fairness enforced?
- How is memory protection verified? Static analysis of the partition's
  binary? Runtime checks in the loader? Both?
