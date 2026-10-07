# HAL Overview

## Tiers

| Arch    | Tier   | Status  | WCET contract |
| ------- | ------ | ------- | ------------- |
| x86_64  | Tier 1 | primary | required      |
| aarch64 | Tier 2 | planned | required      |
| riscv64 | Tier 3 | future  | required      |

**Tier 1** — fully supported, CI runs on it, latency guarantees hold.
**Tier 2** — compiles and boots, but not production-ready.
**Tier 3** — directory exists, nothing works.

The WCET contract column indicates whether the architecture has a
declared maximum cost per HAL operation (see
`docs/contracts/hal-contract.md`). A HAL without a declared cost is
not accepted, regardless of tier.

## What lives here

Everything that is **specific to a CPU architecture**:

- Boot sequence (multiboot2, UEFI, BIOS)
- GDT, IDT, TSS
- Page table format
- Context switch assembly
- Interrupt controllers (APIC, GIC)
- Timers (HPET, TSC, ARM generic timer)

Everything that is **portable** lives in:

- `core/` — the certifiable kernel (scheduler, time, isolation, IPC)
- `lib/no-alloc/` — kernel-safe utilities
- `services/` — non-certifiable subsystems (fs, net, userspace)
- `platform/drivers/` — drivers, under the driver contract

## Adding a new architecture

1. Copy `platform/hal/x86_64/` as a template into `platform/hal/<arch>/`.
2. Implement `boot/`, `cpu/`, `mm/`, `interrupts/`, `timers/`.
3. Declare a WCET for every HAL operation in `platform/hal/contracts/`.
4. Add a build profile under `configs/<profile>/<arch>.defconfig`.
5. Update this file and the CI matrix.

## Non-goals

Portability is not pursued for its own sake. A HAL whose operations
have no declared maximum cost introduces variance and is rejected —
even if it works. See `docs/contracts/hal-contract.md`.
