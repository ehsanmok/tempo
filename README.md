# tempo

[![CI](https://github.com/ehsanmok/tempo/actions/workflows/ci.yml/badge.svg)](https://github.com/ehsanmok/tempo/actions)
[![Docs](https://github.com/ehsanmok/tempo/actions/workflows/docs.yaml/badge.svg)](https://ehsanmok.github.io/tempo)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Minimal UTC timestamp and duration types for Mojo.

`Timestamp` wraps a single `gettimeofday(2)` FFI call; all calendar arithmetic
uses Howard Hinnant's public-domain Gregorian algorithm in pure Mojo. `Duration`
stores a signed second count with a compact human-readable format (`"1d2h30m0s"`).

## Installation

Add tempo to your project's `pixi.toml`:

```toml
[workspace]
channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
preview = ["pixi-build"]

[dependencies]
tempo = { git = "https://github.com/ehsanmok/tempo.git", branch = "main" }
```

Then run:

```bash
pixi install
```

Requires [pixi](https://pixi.sh) (pulls Mojo nightly automatically).

## Quick Start

```mojo
from tempo import Timestamp, Duration

# Current time
var t = Timestamp.now()
print(t)               # "2026-04-06T14:30:00Z"
print(t.unix_secs())   # seconds since epoch
print(t.unix_ms())     # milliseconds since epoch

# Shift forward
var later = t.add(Duration.from_hours(2))
print(later.since(t).hours())  # 2

# Parse and format
var parsed = Timestamp.parse_iso8601("2026-01-01T00:00:00Z")
print(parsed.format_iso8601())  # "2026-01-01T00:00:00Z"

# Duration arithmetic
var d = Duration.from_hours(1) + Duration.from_minutes(30)
print(d)          # "1h30m0s"
print(d.secs())   # 5400
```

## Timestamp vs Duration: When to Use Which

| Need                          | Type        | Example                               |
|-------------------------------|-------------|---------------------------------------|
| Wall-clock instant            | `Timestamp` | `Timestamp.now()`                     |
| Span of time                  | `Duration`  | `Duration.from_days(7)`               |
| Shift a timestamp             | both        | `t.add(Duration.from_hours(3))`       |
| Elapsed time between instants | `Duration`  | `b.since(a).minutes()`                |
| ISO 8601 round-trip           | `Timestamp` | `parse_iso8601` / `format_iso8601`    |

## Example

```mojo
from tempo import Timestamp, Duration

def main() raises:
    var t = Timestamp.now()
    print("Now:      ", t)

    var d = Duration.from_days(30)
    var future = t.add(d)
    print("In 30d:   ", future)

    var elapsed = future.since(t)
    print("Elapsed:  ", elapsed)    # "30d0h0m0s"
    print("Days:     ", elapsed.days())  # 30

    # ISO 8601 round-trip
    var iso = "2026-06-15T10:45:30Z"
    var parsed = Timestamp.parse_iso8601(iso)
    print("Parsed:   ", parsed)
    print("OK:       ", String(parsed) == iso)  # True
```

Run it:

```bash
pixi run example
```

## Performance

Benchmarks on Apple M-series (run `pixi run bench` to reproduce):

| Operation                   | Approx. time |
|-----------------------------|--------------|
| `Timestamp.now()`           | < 200 ns     |
| `from_unix_secs()`          | < 1 ns       |
| `parse_iso8601()`           | < 10 ns      |
| `format_iso8601()`          | < 200 ns     |
| `Duration.from_hours()`     | < 1 ns       |
| `Duration` arithmetic       | < 1 ns       |
| `Timestamp.add(d)`          | < 1 ns       |
| `Timestamp.since(t)`        | < 1 ns       |

## Development

```bash
pixi run tests           # all tests
pixi run test-timestamp  # Timestamp tests
pixi run test-duration   # Duration tests

pixi run bench           # throughput benchmarks
pixi run example         # run examples/example.mojo

pixi run -e dev docs     # build + serve API docs locally
```

Full API reference: [ehsanmok.github.io/tempo](https://ehsanmok.github.io/tempo)

## License

[MIT](LICENSE)
