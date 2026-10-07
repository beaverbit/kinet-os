<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/logo-light.png">
    <img alt="KinetOS" src="assets/logo-light.png" width="600">
  </picture>
</p>

# KinetOS

A portable, low-latency operating system focused on predictable performance for interactive and critical workloads.

## Focus

KinetOS targets **tail latency** (p99, p999) and **predictability**, not average throughput. The goal is an operating system where latency is a requirement, not a consequence.

The focus is on the extreme percentiles of the latency distribution — the cases that the average hides and that define real experience. A system can have high throughput and still fail when p99 spikes. KinetOS treats these cases as the primary problem, not as statistical noise.

Designed for workloads where every microsecond matters. In **remote surgery**, it means the surgeon's command reaches the robot within a predictable bound, with no delay that compromises the procedure. In **aircraft and drones**, it means the control system responds deterministically, with no jitter affecting flight stability. In **critical infrastructure systems**, it means timing failures do not propagate to the rest of the mesh. In **gaming**, it means consistent frame time and minimal input lag, with no stutter. In **APIs**, it means the slowest request still responds within a bound. In **real-time networking**, it means packets processed without jitter, with deterministic timing. In **embedded systems**, it means precise control over hardware with limited resources.

These examples illustrate the problem, but they do not define the scope. Any workload where worst-case predictability is a requirement — today or in the future — is a valid target. As systems become more interactive, distributed, and time-sensitive, the demand for predictable latency grows, and KinetOS is built to follow that movement.

KinetOS is not a general-purpose operating system. It is an operating system for latency-critical workloads, where worst-case predictability matters as much as average-case speed.

## Documentation

See [Documentation](docs/) for the full documentation index.

## License

GPLv2 — see [LICENSE](LICENSE).
