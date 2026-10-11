# Contributing to KinetOS

Before you start, read this document end to end. KinetOS is a research project
with a narrow scope and a specific philosophy. Contributions that do not fit the
philosophy will be rejected, regardless of code quality.

---

## Before you start

KinetOS is an operating system focused on **tail latency (p99, p999)** and
**worst-case predictability**. Every design decision is evaluated by its impact
on tail latency (Decision 009 in `docs/DECISIONS_KERNEL.md`).

Any change that improves average throughput but worsens worst-case latency will
be rejected. This is not negotiable.

Before writing code, read:

1. `README.md` — what KinetOS is and what it does not promise.
2. `docs/DECISIONS_KERNEL.md` — kernel architecture decisions.
3. `docs/DECISIONS_PROJECT.md` — process decisions.
4. `docs/RESEARCH.md` — research hypotheses and measurement methodology.
5. `docs/ROADMAP.md` — what phase the project is in.
6. `docs/COMMITS.md` — commit convention, including latency measurement rules.

---

## Development setup

### Requirements

- `gcc` or `clang` with cross-compilation support
- `nasm` (for x86_64 boot stubs)
- `qemu-system-x86_64`
- `gdb` (for kernel debugging)
- `make`

### Build

```sh
make defconfig
make
make run
```

### Debug

```sh
make debug
# in another terminal:
gdb -ex "target remote :1234"
```

---

## Coding style

· Follow the Linux kernel coding style, adapted by .clang-format.
· 4 spaces, no tabs.
· 100 columns max.
· Run scripts/format.sh before committing.

If .clang-format and this document disagree, .clang-format wins. If both
disagree with the Linux style, the Linux style wins — unless a Decision says
otherwise.

---

## Commit messages

Use Conventional Commits. The full
convention, including types, scopes, breaking changes, and the special rules for
latency-impacting changes, is in docs/COMMITS.md.

Quick reference:

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

Example:

```
perf(sched): reduce p999 wakeup latency by 12%

Before: p50=1.2us p99=4.1us p999=18.3us jitter=17.1us (TSC, 100k samples)
After:  p50=1.1us p99=3.6us p999=16.1us jitter=15.0us (TSC, 100k samples)

Environment: Intel i7-9700K, 3.6 GHz fixed, turbo off, SMT off, cores 4-7
isolated.

Refs: Decision 007 in DECISIONS_KERNEL.md
```

---

## Testing

All PRs must pass:

· make test — unit tests.
· make test-integration — boot in QEMU (when implemented; see Phase 9 of
  docs/ROADMAP.md).
· make bench — latency benchmarks (when implemented; see Phase 12 of
  docs/ROADMAP.md).

Benchmarks in CI are not authoritative. Latency benchmarks require a
controlled environment: CPU frequency pinned, turbo disabled, no other
workloads on the machine. Results obtained in shared CI runners are marked
emulated or shared and do not replace measurements on dedicated hardware.

If your change touches the critical path, you must run the benchmarks locally
and include the numbers in the PR description. See "Latency policy" below.

---

## Latency policy

If your change touches any of the following paths:

· kernel/src/sched/
· kernel/src/irq/
· kernel/src/time/
· arch/*/interrupts/
· arch/*/timers/

You must include before/after latency measurements in the PR description.
This is required by Decision 011 in docs/DECISIONS_KERNEL.md and detailed in
docs/COMMITS.md.

The measurements must include:

· p50, p99, p999 — the percentiles defined in Decision 010 in
  docs/DECISIONS_KERNEL.md.
· Jitter — defined as p999 - p50 in the same run.
· Time source — TSC or HPET (Decision 010).
· Environment — CPU model, frequency, turbo state, SMT state, isolation.
· Sample count — minimum 10,000 for p99, 100,000 for p999 (Decision 010).

If the measurement infrastructure does not yet exist (Phase 7 of
docs/ROADMAP.md), state so explicitly in the PR description. This is allowed
but should be rare.

PRs that touch the critical path without measurements will be rejected, even if
the code is correct.

---

## Documentation

If your change implements, modifies, or invalidates a Decision, update the
corresponding file under docs/:

· docs/DECISIONS_KERNEL.md — for kernel architecture decisions.
· docs/DECISIONS_PROJECT.md — for process decisions.

If your change affects a research hypothesis in docs/RESEARCH.md, note it in
the PR description. If the change makes a hypothesis testable, say so.

Docs are written in English (Decision 008 in docs/DECISIONS_PROJECT.md).
Diagrams use Mermaid when possible.

---

What will be rejected

The following changes will be rejected, regardless of code quality:

· Changes that improve average throughput but worsen worst-case latency.
· Changes that add fairness as a goal to the scheduler.
· Changes that introduce dynamic allocation on the critical path (Decision 009
  in docs/DECISIONS_KERNEL.md).
· Changes that add POSIX or Linux ABI compatibility (non-goal in README.md).
· Changes that make the kernel depend on libc, a runtime, or a garbage
  collector (Decision 001 in docs/DECISIONS_KERNEL.md).
· Changes that move device drivers to userspace (Decision 008 in
  docs/DECISIONS_KERNEL.md).
· Changes that promise provable bounds on x86_64 commodity hardware (Decision
  012 in docs/DECISIONS_KERNEL.md).
· Changes that touch the critical path without before/after latency
  measurements (see "Latency policy" above).
· Changes that renumber or delete an existing Decision without a new Decision
  superseding it.

If you believe one of these rules should change, open an issue with a proposal
for a new Decision. Do not send a PR that contradicts a Decision.

---

## License

By contributing, you agree that your contributions will be licensed under
GPLv2 (see LICENSE).

---

## References

· README.md
· docs/DECISIONS_KERNEL.md
· docs/DECISIONS_PROJECT.md
· docs/RESEARCH.md
· docs/ROADMAP.md
· docs/COMMITS.md
· LICENSE
· CODE_OF_CONDUCT.md
· SECURITY.md