# Certification Strategy

## Status

Proposed. This document defines the certification targets, the
certifiable subset of the codebase, and the traceability process. It
depends on every other design and contract document in the repository.

## Purpose

KinetOS claims to be suitable for latency-critical workloads. Some of
those workloads — remote surgery, aircraft control, industrial safety —
are subject to regulatory certification. This document defines:

- Which certification standards KinetOS targets.
- What subset of the codebase is subject to certification.
- How requirements trace to code, tests, and evidence.
- What the project does **not** claim to certify.

## Target standards

KinetOS targets the following standards, in order of priority:

| Standard      | Domain                | Priority |
| ------------- | --------------------- | -------- |
| DO-178C       | Airborne software     | 1        |
| IEC 61508     | Industrial safety     | 2        |
| ISO 26262     | Automotive            | 3        |
| IEC 62304     | Medical device software | 3      |

The priorities reflect the level of design constraint each imposes.
DO-178C is the most demanding and drives the architecture. Standards
lower in priority are satisfied by the same architecture with
additional evidence where required.

## Certification boundary

Not all of KinetOS is subject to certification. The boundary is:

| Component                          | Certifiable |
| ---------------------------------- | ----------- |
| `core/`                            | Yes         |
| `platform/hal/`                    | Yes         |
| `platform/drivers/certified/`      | Yes         |
| `platform/drivers/partitioned/`    | No          |
| `platform/boot/`                   | Partial     |
| `services/`                        | No          |
| `lib/no-alloc/`                    | Yes         |
| `lib/general/`                     | No          |
| `validation/`                      | Partial     |

"Partial" means: the component is not itself certified, but its
verification contributes evidence to the certified artifact.

The boundary is enforced structurally:

- The certified subset does not depend on the non-certified subset.
  A dependency from `core/` to `services/` is a build error.
- The non-certified subset runs in partitions, isolated by the
  mechanisms in `docs/design/isolation-model.md`.
- A failure in the non-certified subset cannot propagate to the
  certified subset.

This is a **separation kernel** architecture. The certified artifact is
the kernel plus the certified drivers; everything else is a passenger.

## Design constraints imposed by certification

The following constraints are **mandatory** because certification
requires them. They are not preferences.

- **No dynamic allocation in `core/`.** See `docs/design/memory-model.md`.
- **No recursion in `core/`.** Required for static WCET analysis. See
  `docs/contracts/wcet-analysis.md`.
- **Bounded loops in `core/`.** Same reason.
- **No function pointers in `core/` unless statically resolved.**
  Required for both WCET analysis and verification.
- **Single entry, single exit** in critical functions, where feasible.
  Required for traceability.
- **No undefined behavior.** `core/` is compiled with `-fno-strict-aliasing`
  and all warnings as errors.
- **Deterministic error handling.** Every error path is declared and
  bounded. No `panic` in recoverable paths.

These constraints are enforced by the build system, not by review.

## Traceability

Every requirement traces through the following chain:

```
Requirement (docs/)
    → Design decision (docs/design/)
    → Code (core/, platform/)
    → Test (validation/)
    → Evidence (CI report)
```

### Requirements

Requirements live in `docs/requirements/` (to be created). Each has a
unique identifier (e.g., `REQ-SCHED-001`). A requirement is a statement
about observable behavior, not an implementation detail.

### Design decisions

Each design document references the requirements it satisfies. A design
decision without a requirement is a defect (over-engineering). A
requirement without a design decision is a defect (missing coverage).

### Code

Every source file in `core/` and `platform/` declares the requirements
it implements in a header comment:

```c
/*
 * Implements: REQ-SCHED-001, REQ-SCHED-004
 * Refines:    design/execution-model.md, section "Decision"
 */
```

### Tests

Every test in `validation/` declares the requirement it verifies:

```c
/*
 * Verifies: REQ-SCHED-001
 * Method:   adversarial measurement under partition contention
 */
```

### Evidence

CI produces a per-commit report mapping requirements to verification
status:

- **Verified**: test passes, WCET within tolerance.
- **Failed**: test fails, or WCET exceeds tolerance.
- **Untested**: no test references the requirement.
- **Obsolete**: requirement is superseded, no longer verified.

A requirement that is **Untested** or **Failed** blocks release.

## What is not certified

KinetOS **does not** claim to certify:

- The system as a whole. Certification is per-deployment, and the
  deployer is responsible for the final artifact.
- `services/` (filesystem, network, userspace). These run in partitions
  and their certification is out of scope.
- `platform/drivers/partitioned/`. These run in partitions.
- Any code outside the certified subset.

A deployer who needs certification integrates the certified subset into
their artifact and produces their own evidence for the parts they add.

## Evidence artifacts

The following artifacts are produced and versioned with the source:

- **WCET declarations** — in `driver.toml` and build configs. Part of
  the source tree.
- **WCET measurements** — generated by CI, stored per release.
- **Coverage reports** — statement, branch, and MC/DC coverage for
  `core/`. Generated by CI.
- **Traceability matrix** — generated by CI from requirement
  annotations.
- **Design review records** — ADRs in `docs/DECISIONS_*.md`.
- **Build reproducibility record** — hash of source tree, toolchain
  versions, and produced binary.

These are the same artifacts a certification body would expect, kept
in the repository from day one.

## Process

The certification process is:

1. Requirements are written in `docs/requirements/` before
   implementation of the requirement begins.
2. Design documents reference requirements.
3. Code references design documents and requirements.
4. Tests reference requirements.
5. CI produces evidence.
6. A release is only cut when the traceability matrix shows no
   **Untested** or **Failed** requirements.

This is the **same process** the project would follow if it were being
certified. The difference is that no certification body is currently
engaged. The process exists so that when a deployer wants to certify,
the evidence is already there.

## Non-goals

- KinetOS is not itself certified. It is designed to be **certifiable**.
- The project does not maintain certified toolchains. Deployers are
  responsible for their toolchain qualification.
- The project does not produce a "safety manual". Deployers produce
  their own, based on the design and contract documents.
- The project does not guarantee that any specific deployment will pass
  certification. It provides the artifacts a certification process
  requires.

## Open questions

- Which level of DO-178C (A/B/C/D) is the primary target? Level A
  imposes the most constraints and is likely the right anchor, but it
  also constrains the C subset heavily.
- Should requirements live in the repository, or in a separate
  requirements management tool? Repository-based is simpler; tool-based
  is more standard for certification.
- How is the reference platform validated? Certification typically
  requires the platform to be qualified, not just measured.
- Is MC/DC coverage achievable for `core/` given the constraints? If
  not, what evidence substitutes for it?
