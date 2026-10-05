# Security Policy

## Supported Versions

KinetOS is pre-alpha. Only the `main` branch receives fixes.

| Version | Supported |
| ------- | --------- |
| main    | :white_check_mark: |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Email the maintainer (see GitHub profile [@beaverbit](https://github.com/beaverbit)) with:

- Description of the issue
- Reproduction steps (QEMU command, config, and inputs)
- Affected version / commit
- Impact assessment (kernel panic, memory corruption, privilege escalation, DoS)

**Response time:** acknowledgment within 7 days, fix within 30 days.

## Scope

In scope:

- Kernel memory corruption or unsafe memory handling
- Privilege escalation (userspace → kernel)
- Denial of service through malicious syscall arguments
- Scheduler or latency guarantee violations triggerable by unprivileged input
- Information leaks (kernel memory exposure to userspace)

Out of scope:

- Bugs that require physical access to the machine
- Issues in third-party bootloaders or firmware
- Known limitations documented in the README
