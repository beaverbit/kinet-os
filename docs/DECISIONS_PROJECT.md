---

## Decision 015: CI/CD — planned from the start (supersedes 011)

**Status:** Accepted

**Context:**
Decision 011 deferred CI/CD to a future phase, reasoning that it would be
unnecessary overhead before the project had code. After writing
`docs/design/` and `docs/contracts/`, this reasoning no longer holds:

- The design documents specify architectural invariants (separation
  between `core/` and `services/`, no dynamic allocation in `core/`,
  no floating-point in `core/`, WCET declarations per driver and HAL
  operation).
- `docs/contracts/wcet-analysis.md` assumes that CI runs on every commit
  to compare declared and measured WCETs.
- `docs/design/certification.md` assumes that CI produces traceability
  evidence and coverage reports from day one.
- `CONTRIBUTING.md` and `docs/ROADMAP.md` both reference CI enforcement
  of architectural rules.

Deferring CI would mean that these invariants are enforced only by code
review — which is exactly the failure mode the documents are designed
to avoid. Once code exists, a rule that is not mechanically enforced
erodes under pressure.

**Alternatives considered:**
1. Keep Decision 011 (defer CI).
2. Set up CI now, in full.
3. Plan CI now, implement it in phases (minimal now, expand later).

**Decision:**
Plan CI from the start, implement it in phases.

- **Phase 1 (now):** the CI workflow is committed to the repository, but
  runs only the architectural invariant checks that are independent of
  code (directory structure, forbidden includes, forbidden constructs).
  It does not run tests or benchmarks, because there is no code to test.
- **Phase 2 (with the first code):** CI adds compilation, unit tests, and
  WCET measurement for the components that exist.
- **Phase 3 (with the first certified driver):** CI adds the traceability
  matrix and coverage reports.

The phase plan is reflected in `docs/ROADMAP.md`.

**Supersedes:** Decision 011 (CI/CD deferred).

**Rationale:**
- Architectural invariants erode if not mechanically enforced. Code
  review alone is not sufficient, especially for a solo maintainer.
- The invariant checks are cheap to write (a few `grep` and shell
  scripts). There is no justification for deferring them.
- Tests and benchmarks genuinely require code. Deferring those is
  reasonable; deferring all of CI is not.
- `docs/contracts/wcet-analysis.md` and `docs/design/certification.md`
  both assume a CI pipeline exists. Those documents would need to be
  rewritten if CI were deferred — which is a worse outcome than
  committing a minimal CI now.

**Consequences:**
- A `.github/workflows/` directory is created with a minimal CI workflow.
- The workflow checks architectural invariants from the first commit.
- When code is added, the workflow expands to compile and test it.
- The workflow is part of the repository, subject to the same review
  process as any other file.
- Failure of an architectural invariant check blocks merge, per
  `CONTRIBUTING.md`.

**References:**
- `CONTRIBUTING.md` — architectural rules and rejection policy.
- `docs/contracts/wcet-analysis.md` — assumes CI exists.
- `docs/design/certification.md` — assumes CI produces evidence.
- `docs/ROADMAP.md` — phased plan for CI.
