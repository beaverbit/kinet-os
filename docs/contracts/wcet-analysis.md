# WCET Analysis

## Status

Proposed. This document defines how worst-case execution times are
declared, measured, verified, and maintained. It is referenced by every
other contract and design document in the repository.

## Purpose

Every temporal guarantee in KinetOS rests on the assumption that WCETs
are known and true. This document defines:

- The reference platform on which WCETs are measured.
- The methodology used to derive them.
- The tools used to verify them.
- The tolerance allowed between declaration and measurement.
- The process by which declarations are kept in sync with code.

## Reference platform

All declared WCETs are measured on the **reference platform**:

- **CPU:** declared per architecture in `platform/hal/<arch>/`.
- **Frequency:** locked at the reference frequency. Dynamic frequency
  scaling (DVFS) is disabled.
- **Cache:** configuration declared per architecture. Cache behavior is
  part of the platform definition.
- **Memory:** bandwidth and latency declared per architecture.
- **Interrupts:** disabled during measurement unless the code path is
  interruptible by design.

The reference platform is a **single, concrete machine** per architecture.
It is not a class or a range. Code that meets its WCET on the reference
platform is not guaranteed to meet it elsewhere; the reference platform
is the definition of correctness for WCET purposes.

## Methodology

WCET is derived from three sources, in order of preference:

1. **Static analysis** — where the tool can prove a bound. Preferred for
   `core/` and `certified` drivers.
2. **Measurement** — where static analysis is not available. Used for
   `partitioned` drivers and IPC paths.
3. **Hybrid** — static analysis of the code, measurement of the hardware
   effects (cache, memory). Used where both apply.

The choice of methodology is per component, not per project. Each
component declares its methodology in its `driver.toml` or in its build
config.

### Static analysis

Static analysis requires:

- Bounded loops (no unbounded `while`).
- No recursion.
- No dynamic dispatch that cannot be resolved statically.
- No indirect jumps that cannot be resolved.

These constraints are enforced by the build system. A component that
violates them cannot use static analysis and must fall back to
measurement.

### Measurement

Measurement requires:

- A workload that exercises the worst case, not the average case.
- Adversarial conditions: cache pressure, memory pressure, contention
  from other partitions.
- Sufficient repetitions to observe the maximum, not an estimate.

Measurement alone is **not sufficient for `core/` or `certified` drivers**.
Those must have a static or hybrid bound. Measurement is used to validate
the static bound, not to replace it.

## Tools

The toolchain is declared per architecture. The current proposal:

- **x86_64:** in-house static analyzer (to be developed) + measurement
  on the reference platform.
- **aarch64:** same.
- **riscv64:** same.

Third-party tools (aiT, Bound-T, RapiTime) are not used. Reasons:

- Licensing prevents redistribution in a GPLv2 project.
- Integration cost is high.
- The subset of C used in KinetOS is small enough to analyze in-house.

This is an open decision. If a third-party tool becomes available under
a compatible license, it should be evaluated.

## Tolerance

A declared WCET and a measured WCET must agree within a tolerance:

- **`core/`:** no tolerance. Declared = measured. A discrepancy is a bug.
- **`certified` drivers:** tolerance declared per driver in `driver.toml`,
  default 5%. A discrepancy beyond tolerance rejects the driver.
- **`partitioned` drivers:** tolerance declared per driver, default 15%.
- **IPC paths:** tolerance declared per channel, default 10%.

Tolerance exists because measurement includes noise from the platform
(cache effects, memory contention, interrupt jitter). It does not exist
to accommodate sloppy analysis.

## Verification process

Every commit that touches `core/`, a `certified` driver, or an IPC path
must run the following in CI:

1. **Compile** the changed component.
2. **Extract** declared WCETs from `driver.toml` or build config.
3. **Measure** the component under adversarial conditions in
   `validation/adversarial/`.
4. **Compare** measured vs. declared. Fail if outside tolerance.
5. **Re-run** the static analyzer where applicable.

CI publishes a report per commit: declared WCETs, measured WCETs, ratio.
A regression in any WCET is flagged for review.

## Keeping declarations in sync

Declared WCETs are part of the codebase, not separate from it. A change
to a component that affects its WCET must update the declaration in the
same commit. The CI check enforces this.

A component whose declaration is out of date is **rejected at merge**.
There is no exception for "temporary" or "will fix later". A WCET that
is not maintained is worse than no WCET, because it creates false
confidence.

## What is not analyzed

- **Non-deterministic hardware** — e.g., branch predictors with
  data-dependent behavior that the tool cannot bound. If a component
  relies on such hardware, it is not admissible to `core/`.
- **Runtime polymorphism** — virtual dispatch, function pointers where
  the target is not statically known. If a component relies on these, it
  cannot use static analysis.
- **Dynamic allocation in `core/`** — not applicable, because `core/`
  does not allocate. If it did, WCET analysis would be impossible.

## Failure modes

- **Declared WCET too low** — the component is rejected by CI. The
  declaration is updated or the code is fixed.
- **Declared WCET too high** — the component is accepted, but flagged
  for review. An over-declared WCET reduces schedulability; it is a
  correctness issue, not just an efficiency one.
- **Measurement noise** — repeated runs that disagree by more than the
  tolerance indicate a problem with the reference platform or the
  workload, not with the component. The platform is re-validated.

## Non-goals

- WCET analysis for `services/` (fs, net, userspace) is not required.
  Those components run in partitions, and their schedulability is
  enforced by the partition scheduler, not by their internal WCET.
- WCET analysis for `lib/general/` is not required. That code does not
  run in the kernel.
- Hard real-time guarantees on non-reference platforms are not provided.
  The reference platform is the definition of correctness.

## Open questions

- Should the static analyzer be developed in-house, or should we invest
  in integrating an existing tool under a compatible license?
- How is the reference platform emulated in CI? Emulation does not
  reproduce cache and memory behavior faithfully. Bare-metal CI runners
  are expensive but necessary for credible WCET.
- What is the process when a component's WCET cannot be bounded? Is it
  rejected entirely, or is it allowed with an "unbounded" declaration
  that disables its temporal guarantees?
