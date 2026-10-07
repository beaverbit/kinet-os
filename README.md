<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo-light.png">
    <img alt="KinetOS" src="assets/logo-light.png" width="600">
  </picture>
</p>

# KinetOS

A portable operating system for latency-critical workloads. KinetOS treats
**tail latency** (p99, p999) and **worst-case predictability** as primary
requirements, not as consequences of average-case design.

## Technical commitments

1. **Tail latency is the metric.** Average throughput is secondary. A system
   with high throughput and unpredictable p999 does not meet the design goal.
2. **Worst case is a requirement.** Bounds are declared and provable, not
   observed post-hoc from benchmarks.
3. **Isolation is structural.** A timing fault in one component does not
   propagate to others.

These commitments constrain the architecture. The kernel is minimal and
certifiable; drivers declare a WCET; filesystem and network run outside the
kernel core; no dynamic allocation is permitted on the critical path.

## Non-goals

KinetOS is not a general-purpose operating system. It deliberately does not
promise:

- Throughput as a primary metric
- Fairness between workloads
- Compatibility with POSIX or Linux ABIs
- Demand paging on the critical path
- Portability pursued for its own sake

Any workload where worst-case predictability is a requirement is in scope.

## Documentation

See [`docs/`](docs/) for the full documentation index.

## License

GPLv2 — see [LICENSE](LICENSE).
