# Contributing to KinetOS

## Before you start

KinetOS is an operating system focused on **tail latency** (p99, p999) and **predictability**. Any change that improves average throughput but worsens worst-case latency will be rejected.

## Development setup

Requirements:

- `gcc` or `clang` with cross-compilation support
- `nasm` (for x86_64 boot stubs)
- `qemu-system-x86_64`
- `gdb` (for kernel debugging)
- `make`

Build:

```bash
make defconfig
make
make run
```

## Coding style

- Follow Linux kernel coding style adapted by `.clang-format`.
- 4 spaces, no tabs.
- 100 columns max.
- Run `scripts/format.sh` before committing.

## Commit messages

Use Conventional Commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` code change that neither fixes a bug nor adds a feature
- `perf:` performance improvement
- `test:` adding or fixing tests
- `chore:` build process, tooling

Example: `sched: reduce p999 wakeup latency by 12%`

## Testing

All PRs must pass:

- `make test` (unit tests)
- `make test-integration` (boot in QEMU)
- `make benchmark-latency` (no regression in p99)

## Latency policy

If your change touches:

- `kernel/sched/`
- `kernel/irq/`
- `kernel/time/`
- `arch/*/interrupts/`
- `arch/*/timers/`

You must include before/after latency measurements in the PR description.

## License

By contributing, you agree that your contributions will be licensed under GPLv2 (see `LICENSE`).