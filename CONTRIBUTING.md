# Contributing to KinetOS

## Before you start

KinetOS is an operating system for **latency-critical workloads**. It targets
**tail latency** (p99, p999) and **worst-case predictability** as primary
requirements, not as consequences of average-case design.

Any change that improves average throughput but worsens worst-case latency
will be rejected. This is not a preference; it is the design goal.

Read [`docs/design/execution-model.md`](docs/design/execution-model.md) before
proposing architectural changes. The execution model anchors every other
decision in the project.

## Development setup

Requirements:

- `gcc` or `clang` with cross-compilation support
- `nasm` (for x86_64 boot stubs)
- `qemu-system-x86_64`
- `gdb` (for kernel debugging)
- `make`
- `limine` (bootloader; see `platform/boot/`)

Build:

```bash
make defconfig
make
make run
```

The build profiles live in `configs/`:

- `configs/hard-rt/` — strict deadlines, abort-on-miss
- `configs/soft-rt/` — relaxed deadlines, log-only
- `configs/minimal/` — smallest footprint, no optional subsystems

## Repository structure

- `core/` — the certifiable kernel. Scheduler, time, isolation, IPC.
- `platform/` — HAL and drivers, under declared temporal contracts.
- `services/` — filesystem, network, userspace. Run in isolated partitions,
  outside the kernel.
- `lib/no-alloc/` — code safe for the critical path. No dynamic allocation.
- `lib/general/` — code that must **not** run in the kernel.
- `validation/` — proof of temporal guarantees: WCET, adversarial, chaos,
  conformance, benchmarks.
- `configs/` — build profiles: `hard-rt`, `soft-rt`, `minimal`.
- `docs/design/` — the architecture. Start with `execution-model.md`.
- `docs/contracts/` — the contracts binding code to guarantees.

## Architectural rules

The following rules are **enforced by CI** (or will be, once CI is in place).
A pull request that violates any of them is rejected automatically,
regardless of code quality.

1. **`core/` must not depend on `services/`.** The certifiable kernel does
   not use filesystem, network, or userspace code.
2. **`lib/no-alloc/` must not call any allocator.** No `malloc`, `calloc`,
   `realloc`, `free`, `kmalloc`, or equivalent.
3. **`core/` must not use floating-point arithmetic.** No `float`, `double`.
   FPU state is not saved on every context switch, and FPU operations have
   data-dependent latency.
4. **`core/` must not use recursion.** Required for static WCET analysis.
5. **`core/` must not use function pointers unless statically resolved.**
   Same reason.
6. **Every driver must have a `driver.toml`** declaring its WCET per
   operation. See `docs/contracts/driver-contract.md`.
7. **Every HAL must implement all required operations** and declare their
   WCET in `hal.toml`. See `docs/contracts/hal-contract.md`.
8. **No `#include` from `core/` to `platform/drivers/partitioned/` or
   `platform/drivers/certified/`** other than through the HAL interface.
   Drivers use the HAL, not the reverse.

If you believe a rule must be violated for a specific change, propose an
ADR in `docs/DECISIONS_KERNEL.md` first. Do not open a PR that violates
a rule and argue in the comments.

## Coding style

- Follow the Linux kernel coding style, adapted by `.clang-format`.
- 4 spaces, no tabs.
- 100 columns maximum.
- Run `scripts/format.sh` before committing.
- Comments explain **why**, not **what**. If the code needs a comment to
  explain what it does, rewrite the code.

## Commit messages

KinetOS follows [Conventional Commits](https://www.conventionalcommits.org/).
See `docs/COMMITS.md` for the full convention.

Format:

```
<type>(<scope>): <description>
```

Types:

- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — code change that neither fixes a bug nor adds a feature
- `perf` — performance improvement
- `test` — adding or fixing tests
- `build` — build system or external dependencies
- `ci` — CI configuration
- `chore` — other changes

Scopes correspond to top-level directories:

- `core` — `core/`
- `platform` — `platform/`
- `services` — `services/`
- `validation` — `validation/`
- `docs` — `docs/`
- `configs` — `configs/`

Example: `perf(core): reduce p999 wakeup latency by 12% in rate-monotonic scheduler`

## Testing

All pull requests must pass:

- `make test` — unit tests in `validation/unit/`
- `make test-integration` — boot in QEMU, run integration tests in
  `validation/integration/`
- `make test-adversarial` — adversarial load in `validation/adversarial/`
- `make benchmark-latency` — no regression in p99, p999

A pull request that regresses p999 by more than 1% is rejected unless it
comes with an ADR justifying the regression.

## Latency policy

If your change touches any of the following, you **must** include
before/after latency measurements in the pull request description:

- `core/sched/`
- `core/exceptions/irq/`
- `core/time/`
- `core/ipc/`
- `platform/hal/*/interrupts/`
- `platform/hal/*/timers/`

Measurements must use the reference platform defined in
`docs/contracts/wcet-analysis.md`. Measurements on other hardware are
informative but not sufficient.

Include:

- p50, p99, p999 before and after
- Jitter (max - min) before and after
- The workload used (must be reproducible)

## WCET declarations

If your change affects a component whose WCET is declared (any `core/`
code path, any certified driver, any HAL operation), you must update the
declaration in the same commit.

Declarations are part of the codebase, not separate from it. A declaration
that is out of date is worse than no declaration, because it creates false
confidence.

See `docs/contracts/wcet-analysis.md` for the declaration format and
tolerances.

## Language

All code, comments, documentation, commit messages, and issues must be
written in **English**. This is an international project released under
GPLv2 and meant to be understood by contributors worldwide.

Internal notes in other languages are permitted in `docs/notes/` (not yet
created), clearly marked as non-official. They are not part of the
project's documentation.

## `.gitkeep` convention

Directories that are part of the planned structure but empty are versioned
with a `.gitkeep` file. When a directory gains real content, delete its
`.gitkeep`.

Do not add `.gitkeep` to directories that will be populated in the same
commit. It is a placeholder, not a ritual.

## Pull request process

1. Open an issue first for non-trivial changes. Describe the problem and
   the proposed approach.
2. If the change touches architecture (any file in `docs/design/` or
   `docs/contracts/`), write or update the relevant design document
   **before** writing code.
3. Implement, with tests in `validation/`.
4. Run the full local suite: `make test`, `make benchmark-latency`.
5. Open the pull request. Include:
   - Link to the issue.
   - Summary of the change.
   - Latency measurements, if the change touches a latency-sensitive path.
   - WCET declaration updates, if applicable.
6. CI runs. A red CI is a blocked PR.
7. Review. A reviewer checks the change against the design documents, not
   only against the code.
8. Merge. Squash if the branch has noisy history; merge commit otherwise.

## What is rejected without discussion

- Changes that violate an architectural rule (see above) without an
  accompanying ADR.
- Changes that regress p999 without justification.
- Changes that add dynamic allocation to `core/`.
- Changes that add floating-point to `core/`.
- Changes that add a new dependency to the kernel without an ADR.
- Changes that bypass the driver contract or HAL contract.
- Changes that add code without updating the corresponding WCET declaration.

## What is welcomed

- New design documents that clarify ambiguous decisions.
- New tests in `validation/` that exercise adversarial conditions.
- New HAL ports that satisfy the HAL contract.
- Bug fixes with a reproduction.
- Documentation improvements that make the architecture clearer.
- Benchmarks that expose tail-latency problems we have not seen.

## License

By contributing, you agree that your contributions will be licensed under
GPLv2 (see [`LICENSE`](LICENSE)).
