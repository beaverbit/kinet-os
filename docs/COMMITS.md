# Commit Convention

KinetOS follows the [Conventional Commits](https://www.conventionalcommits.org/)
specification. This document defines the types, scopes, and special rules used
in this project.

---

## Format

```

<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]

```

- **type** — one of the types listed below.
- **scope** — optional, one of the scopes listed below. Use when the change is
  confined to a single subsystem.
- **!** — marks a breaking change (see "Breaking changes" below).
- **description** — imperative mood, lowercase, no trailing period.
- **body** — optional. Explains *why*, not *what*. The diff explains the
  *what*.
- **footer** — optional. Used for `BREAKING CHANGE:`, `Refs:`, `Tested-on:`,
  and `Measured-on:` (see "Latency-impacting changes" below).

---

## Types

| Type | Meaning |
|---|---|
| `feat` | A new feature. |
| `fix` | A bug fix. |
| `docs` | Documentation only. |
| `style` | Changes that do not affect the meaning of the code (whitespace, formatting). |
| `refactor` | A code change that neither fixes a bug nor adds a feature. |
| `perf` | A code change that improves performance. |
| `test` | Adding missing tests or correcting existing tests. |
| `build` | Changes to the build system or external dependencies. |
| `ci` | Changes to CI configuration and scripts. |
| `bench` | Adding or updating benchmarks. |
| `chore` | Other changes that do not modify `src` or `test` files. |

**Note on `bench`:** this type is specific to KinetOS. It is used for commits
that add, modify, or fix a benchmark, or that update a stored benchmark result
under `validation/`. It is distinct from `test`, which is for unit and
integration tests.

---

## Scopes

Use a scope when the change is confined to a single subsystem. Omit the scope
for changes that span multiple subsystems or that affect only documentation.

| Scope | Covers |
|---|---|
| `boot` | `boot/`, Limine integration, linker script. |
| `mm` | `kernel/src/memory/`, physical and virtual memory. |
| `sched` | `kernel/src/sched/`, run queue, context switch. |
| `irq` | Interrupt handling, IDT, APIC/PIC. |
| `time` | `kernel/src/time/`, TSC, HPET, APIC timer. |
| `drivers` | `kernel/src/drivers/`, WCET contract, watchdog. |
| `syscall` | Syscall entry and exit paths, syscall table. |
| `arch` | `arch/`, architecture-specific code (`x86_64/`, future `arm/`). |
| `services` | `services/`, filesystem and network stacks outside the kernel core. |
| `userspace` | `userspace/`, ELF loader, libc subset, `init`. |
| `build` | Makefile, `configs/`, toolchain integration. |
| `bench` | Benchmarks under `bench/` or `validation/`. |
| `docs` | `docs/`, README, ADRs, commit convention. |

---

## Breaking changes

A breaking change is any change that invalidates a documented Decision, changes
a public interface (syscall ABI, driver registration structure), or makes a
previous benchmark result non-comparable.

Mark it with `!` after the type/scope:

```

feat(sched)!: replace run queue with priority-based design

```

Or with a `BREAKING CHANGE:` footer:

```

feat(sched): replace run queue with priority-based design

BREAKING CHANGE: sched_enqueue() no longer takes a priority argument.
Callers must use sched_enqueue_prio() instead. This invalidates benchmark
results from before commit abc1234.

```

A breaking change requires a MAJOR version bump (see Decision 007 in
`DECISIONS_PROJECT.md`).

---

## Latency-impacting changes

Any change that touches the critical path must include before/after latency
measurements in the commit body. This is required by the "Contributing" section
of the README and by Decision 011 in `DECISIONS_KERNEL.md`.

The critical path is:

- `kernel/src/sched/`
- `kernel/src/irq/`
- `kernel/src/time/`
- `arch/*/interrupts/`
- `arch/*/timers/`

For these paths, the commit body must include:

- **Before:** p50, p99, p999, and jitter, with the time source (TSC or HPET).
- **After:** same metrics, same conditions.
- **Environment:** CPU model, frequency, turbo state, SMT state, isolation.
- **Sample count:** must meet the minimums in Decision 010 in
  `DECISIONS_KERNEL.md` (10,000 for p99, 100,000 for p999).

Example:

```

perf(sched): reduce p999 wakeup latency by 12%

Before: p50=1.2us p99=4.1us p999=18.3us jitter=17.1us (TSC, 100k samples)
After:  p50=1.1us p99=3.6us p999=16.1us jitter=15.0us (TSC, 100k samples)

Environment: Intel i7-9700K, 3.6 GHz fixed, turbo off, SMT off, cores 4-7
isolated.

Refs: Decision 007 in DECISIONS_KERNEL.md

```

If a change touches the critical path but measurements are not yet possible
(e.g., the measurement infrastructure does not exist yet), the commit must say
so explicitly:

```

refactor(sched): extract run queue into its own module

No latency measurements: measurement infrastructure (Phase 7) not yet
implemented.

```

This is allowed but should be rare, and only before Phase 7 of the roadmap.

---

## Examples

```

feat(boot): integrate Limine bootloader
fix(mm): correct PDPT index calculation for huge pages
docs(kernel): add Decision 010 on time model
refactor(sched): extract run queue into its own module
perf(time): reduce ktime_now() read latency to 24 cycles
bench(sched): add bench_sched_wakeup for p99/p999 measurement
chore(build): update Makefile to include kernel/src/time/

```

---

## Rules

- **Imperative mood.** "add", not "added" or "adds".
- **Lowercase description.** No capital letter after the colon.
- **No trailing period.** The description is a title, not a sentence.
- **One logical change per commit.** If you need "and" in the description, the
  commit is probably two commits.
- **English only.** See Decision 008 in `DECISIONS_PROJECT.md`.
- **Reference Decisions.** When a commit implements or changes a Decision,
  reference it in the footer: `Refs: Decision 010 in DECISIONS_KERNEL.md`.

---

## References

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Semver](https://semver.org)
- Decision 008 in `DECISIONS_PROJECT.md` (English as the standard)
- Decision 010 in `DECISIONS_KERNEL.md` (time model and measurement)
- Decision 011 in `DECISIONS_KERNEL.md` (driver WCET contract)

**End of document.**