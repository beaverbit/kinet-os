# Tests

## Layout

- `unit/` — pure functions, no kernel state. Run on host with `make test-unit`.
- `integration/` — boot the kernel in QEMU and run assertions inside it.
- `stress/` — long-running workloads to shake out races and leaks.
- `latency/` — measure tail latency; not pass/fail, but tracked against baselines.

## Running

```bash
make test              # unit + integration
make test-unit         # fast, host-only
make test-integration  # boots QEMU
make test-stress       # long
make benchmark-latency # numbers, not pass/fail
```

## Adding tests

- Unit tests live next to the code they test (e.g. `lib/string/test_memcpy.c`).
- Integration tests live in `tests/integration/` with a `run.sh` that boots and checks output.
- Any fix for a bug should come with a regression test.