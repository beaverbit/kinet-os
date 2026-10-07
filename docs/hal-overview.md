# Architecture Support

## Tiers

| Arch    | Tier   | Status  |
| ------- | ------ | ------- |
| x86_64  | Tier 1 | primary |
| aarch64 | Tier 2 | planned |
| riscv64 | Tier 3 | future  |

**Tier 1** — fully supported, CI runs on it, latency guarantees hold.
**Tier 2** — compiles and boots, but not production-ready.
**Tier 3** — directory exists, nothing works.

## What lives here

Everything that is **specific to a CPU architecture**:

- Boot sequence (multiboot, UEFI, etc.)
- GDT, IDT, TSS
- Page table format
- Context switch assembly
- Interrupt controllers (APIC, GIC)
- Timers (HPET, TSC, ARM generic timer)

Everything that is **portable** lives in `kernel/`, `lib/`, `fs/`, `net/`, `drivers/`.

## Adding a new architecture

1. Copy `arch/x86_64/` as a template.
2. Implement `boot/`, `cpu/`, `mm/`, `interrupts/`, `timers/`.
3. Add a `defconfig_<arch>` in `configs/`.
4. Update this file and the CI matrix.