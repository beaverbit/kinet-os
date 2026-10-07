# Driver Contract

Every driver in `platform/drivers/` must declare its temporal properties.
A driver that does not declare is rejected by the build system; it never
reaches code review.

## Declaration format

A driver declares its properties in a `driver.toml` file at its root:

```toml
[driver]
name = "e1000"
type = "net"
runs_in = "partitioned"   # "certified" or "partitioned"

[operations.read]
wcet_ns = 4200
may_block = false
may_allocate = false
reentrant = true

[operations.write]
wcet_ns = 8100
may_block = true          # waits for DMA completion
max_block_ns = 50000
may_allocate = false
reentrant = false

[operations.ioctl]
wcet_ns = 1200
may_block = false
may_allocate = false
reentrant = true
```

The build system parses `driver.toml` and generates a C header with the
declared properties. The driver implementation must not exceed them.

## Fields

- `name` — driver identifier, unique within its type.
- `type` — `block`, `char`, `net`, `bus`, `timer`, `interrupt`.
- `runs_in` — where the driver executes:
  - `certified`: inside the certifiable kernel (`platform/drivers/certified/`).
    Reserved for drivers that are part of the certification artifact.
  - `partitioned`: inside an isolated partition
    (`platform/drivers/partitioned/`). The default.
- `operations` — one entry per public operation the driver exposes.
  - `wcet_ns` — worst-case execution time in nanoseconds, on the reference
    platform declared in `docs/contracts/wcet-analysis.md`.
  - `may_block` — `true` if the operation can block. If `true`,
    `max_block_ns` must also be declared.
  - `max_block_ns` — maximum blocking time in nanoseconds. Required if
    `may_block` is `true`.
  - `may_allocate` — `true` if the operation may call into the allocator.
    Default `false`. `true` is rejected for `certified` drivers.
  - `reentrant` — `true` if the operation can be called from multiple
    contexts concurrently. Default `false`.

## Verification

Declared WCETs are verified by:

1. **Static analysis** where possible (see `docs/contracts/wcet-analysis.md`).
2. **Adversarial measurement** under `validation/adversarial/` — the driver
   is exercised under worst-case conditions, and measured latencies are
   compared against declarations.
3. **Code review** — a driver whose declaration does not match its
   implementation is rejected on review, even if measurements pass.

A driver whose measured WCET exceeds its declared WCET by more than the
tolerance declared in `docs/contracts/wcet-analysis.md` is rejected.

## Runtime enforcement

- If a `certified` driver exceeds its declared WCET at runtime, the kernel
  logs the violation and (in `hard-rt` profile) halts.
- If a `partitioned` driver exceeds its declared WCET, the partition's
  fault handler is invoked. See `docs/design/isolation-model.md`.

## Example

See `platform/drivers/partitioned/net/e1000/driver.toml` for a complete
example.

## Non-goals

- Drivers are not required to be portable across architectures. A driver
  targets one HAL.
- Dynamic driver loading is not supported. All drivers are built into the
  image at build time.
