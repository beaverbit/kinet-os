# Roadmap

## Phase 0 — Architecture (done)

- [x] Tree reorganization
- [x] Design documents (`docs/design/`)
- [x] Contract documents (`docs/contracts/`)
- [x] ADRs reconciled with design

## Phase 1 — Foundation

- [ ] Build system (`Makefile` + profiles)
- [ ] HAL contract for x86_64 (`hal.toml`)
- [ ] Boot via Limine (or Multiboot2 if Limine is dropped)
- [ ] Serial output (not VGA — serial is deterministic, VGA is not)

## Phase 2 — Temporal core

- [ ] Partition scheduler (temporal partitioning)
- [ ] Rate-monotonic scheduler inside partitions
- [ ] Timer / deadline management
- [ ] Interrupt threading (top/bottom half)
- [ ] WCET analysis infrastructure

## Phase 3 — Isolation

- [ ] MMU setup with per-partition page tables
- [ ] Partition fault handlers
- [ ] Budget enforcement / replenishment

## Phase 4 — IPC

- [ ] Cross-partition synchronous IPC with deadlines
- [ ] Intra-partition mutex with priority ceiling
- [ ] IPC WCET measurement

## Phase 5 — Services (outside the kernel)

- [ ] Basic filesystem in a partition
- [ ] Basic network stack in a partition
- [ ] Userspace runtime in a partition

## Phase 6 — Validation and certification

- [ ] Adversarial load injection
- [ ] Chaos testing for temporal faults
- [ ] Traceability matrix (requirements → code → tests)
- [ ] CI enforcing architectural invariants

## Notes

- This roadmap replaces the previous linear one. Phases are gated:
  Phase N+1 does not start until Phase N is complete.
- See `docs/design/` for the architecture and `docs/contracts/` for
  the contracts each phase must satisfy.
