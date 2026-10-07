# Commit Convention

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

- `feat`: A new feature.
- `fix`: A bug fix.
- `docs`: Documentation only changes.
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc).
- `refactor`: A code change that neither fixes a bug nor adds a feature.
- `perf`: A code change that improves performance.
- `test`: Adding missing tests or correcting existing tests.
- `build`: Changes that affect the build system or external dependencies.
- `ci`: Changes to our CI configuration files and scripts.
- `chore`: Other changes that don't modify src or test files.

## Scopes

Scopes correspond to top-level directories of the repository. Use the
scope when the change is confined to one area; omit it when the change
spans multiple areas.

- `core`: `core/` — the certifiable kernel.
- `platform`: `platform/` — HAL and drivers.
- `services`: `services/` — filesystem, network, userspace.
- `validation`: `validation/` — tests, benchmarks, WCET analysis.
- `docs`: `docs/` — documentation.
- `configs`: `configs/` — build profiles.

## Examples

- `feat(core): add rate-monotonic scheduler`
- `fix(platform): resolve stack alignment issue in x86_64 HAL boot stub`
- `perf(core): reduce p999 wakeup latency by 12% in partition switch`
- `docs(design): clarify deadline violation behavior in execution model`
- `build(configs): add soft-rt profile for x86_64`
- `refactor(validation): move adversarial workload to its own module`
- `chore: update .clang-format to 100 columns`

## Rules

- Use the imperative mood in the description ("add", not "added" or "adds").
- Do not capitalize the first letter of the description.
- Do not end the description with a period.
- Keep the first line under 72 characters.
- Use the body to explain **what** and **why**, not **how**. The code
  shows the how.
- Reference the issue or ADR in the footer when applicable:

  ```text
  perf(core): reduce p999 wakeup latency by 12%

  Replace the linear scan in the partition scheduler with a
  priority-ordered runqueue. This removes an O(n) path from the
  critical section, which was the dominant source of jitter under
  load.

  Refs: #42
  ADR: docs/DECISIONS_KERNEL.md, Decision 010
  ```

- A commit that changes a declared WCET must update the declaration in
  the same commit. See `docs/contracts/wcet-analysis.md`.

## Breaking changes

A breaking change is marked with `!` after the type or scope:

```text
feat(core)!: change partition admission API
```

Or with a `BREAKING CHANGE:` footer:

```text
feat(core): change partition admission API

BREAKING CHANGE: `sched_admit_partition` now requires a WCET
declaration as its third argument. Callers must be updated.
```

A breaking change must be accompanied by an ADR in
`docs/DECISIONS_KERNEL.md` or `docs/DECISIONS_PROJECT.md`, unless it is
a purely internal change with no external consumers.

## See also

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — the full contribution guide.
- [`docs/ROADMAP.md`](ROADMAP.md) — where the project is going.
