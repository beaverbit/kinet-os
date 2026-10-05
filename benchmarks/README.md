# Benchmarks

KinetOS is judged by **tail latency**, not average. Benchmarks here measure worst-case behavior, not throughput.

## Structure

- `latency/` — wakeup latency, syscall latency, interrupt latency. Reports p50, p99, p999, max.
- `throughput/` — syscalls/sec, context switches/sec. Secondary, but tracked.
- `jitter/` — standard deviation of timer ticks, scheduler wakeup variance.

## Methodology

- Each benchmark reports at least: **p50, p99, p999, max**.
- Runs are done in QEMU with `-smp 4` unless stated otherwise.
- Results are committed as CSV under the benchmark's directory, with a header describing the environment.
- Regressions over 5% in p99 are treated as blockers.

## Running

```bash
make benchmark-latency
make benchmark-jitter
```

Each target builds and runs the corresponding harness, then writes results to `results/<timestamp>.csv`.