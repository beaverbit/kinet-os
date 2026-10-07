# Security Policy

## Supported Versions

KinetOS is pre-alpha. Only the `main` branch receives fixes.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Email the maintainer at `kinet.foundation@gmail.com` with:

- Description of the issue.
- Reproduction steps (QEMU command, build profile, and inputs).
- Affected version or commit hash.
- Impact assessment: kernel panic, memory corruption, privilege escalation,
  or denial of service.

**Response time:** acknowledgment within 7 days, fix within 30 days.

## Scope

### In scope

- Kernel memory corruption or unsafe memory handling in `core/` or
  `platform/hal/`.
- Privilege escalation from a partition to the kernel.
- Denial of service through malicious syscall arguments or malicious IPC
  messages.
- Violation of the temporal isolation guarantees described in
  `docs/design/isolation-model.md` — e.g., a partition that escapes its
  budget or accesses another partition's memory.
- Information leaks: kernel memory or another partition's memory exposed
  to a partition that should not have access.
- Bypass of the driver contract or HAL contract declared in
  `docs/contracts/`.

### Out of scope

- Bugs that require physical access to the machine.
- Issues in third-party bootloaders or firmware (Limine, UEFI, BIOS).
- Known limitations documented in the design documents. In particular:
  - Faults inside `core/` are not isolated — this is by design
    (`docs/design/isolation-model.md`).
  - `platform/drivers/certified/` runs in kernel space — a fault there is
    a system fault (`docs/design/isolation-model.md`).
- Denial of service that requires exhausting a partition's own fixed pool.
  This is a partition fault, not a kernel fault, and is handled by the
  partition's fault handler.

## Disclosure process

1. Report received and acknowledged within 7 days.
2. Maintainer investigates and produces a fix or a mitigation plan.
3. Fix is developed in a private branch, reviewed, and merged.
4. Fix is released in the `main` branch with a security note in
   `docs/CHANGELOG.md` (to be created).
5. Reporter is credited in the security note, unless they request otherwise.

A disclosure is only made public after the fix is available on `main`.

## Not a security issue

The following are design decisions, not vulnerabilities:

- A partition can be denied service by its own code or by a driver running
  inside it. This is containment, not a bug.
- A driver in `platform/drivers/partitioned/` can fault without affecting
  the kernel. This is the intended behavior.
- A `partitioned` driver can exceed its declared WCET. The partition is
  suspended; the kernel is unaffected.
- The kernel does not attempt to recover from faults. It isolates them.

Reports that describe these as "vulnerabilities" will be closed as
non-issues, with a pointer to the relevant design document.
