# KinetOS Documentation

## Design

- [`design/`](design/) — architecture decisions and rationale
  - [latency-budget.md](design/latency-budget.md) — how much latency each subsystem is allowed
  - [scheduler.md](design/scheduler.md) — scheduling model and policies
  - [memory.md](design/memory.md) — physical and virtual memory layout

## Internals

- [`internals/`](internals/) — how the kernel works
  - [boot.md](internals/boot.md) — boot process
  - [interrupts.md](internals/interrupts.md) — interrupt handling
  - [syscalls.md](internals/syscalls.md) — syscall interface

## API

- [`api/`](api/) — syscall and driver interfaces
  - [syscalls.md](api/syscalls.md) — syscall reference
  - [drivers.md](api/drivers.md) — driver model

## Latency

- [`latency/`](latency/) — measurement methodology
  - [methodology.md](latency/methodology.md) — how we measure
  - [benchmarks.md](latency/benchmarks.md) — benchmarks

## Writing docs

- Use Markdown.
- Every design decision that touches latency must include the reasoning and, if possible, numbers.
- Keep diagrams in Mermaid when possible (renders on GitHub).