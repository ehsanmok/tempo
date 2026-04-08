"""Minimal UTC timestamp and duration types for Mojo.

`tempo` provides two composable types:

- `Timestamp` -- a UTC wall-clock instant with microsecond resolution.
  Backed by a single `gettimeofday(2)` FFI call; all calendar arithmetic
  is pure Mojo integer math.
- `Duration` -- a signed span of time stored as whole seconds.  Supports
  all standard arithmetic operators and a compact human-readable format
  (`"1d2h30m0s"`).

## Core API

```mojo
from tempo import Timestamp, Duration

var t = Timestamp.now()
print(t.format_iso8601())           # "2026-04-06T14:30:00Z"
print(t.unix_secs())                # seconds since epoch
print(t.unix_ms())                  # milliseconds since epoch

var d = Duration.from_hours(2) + Duration.from_minutes(30)
print(d)                            # "2h30m0s"
print(d.secs())                     # 9000

var later = t.add(d)
print(later.since(t).hours())       # 2

var parsed = Timestamp.parse_iso8601("2026-01-01T00:00:00Z")
print(parsed.unix_secs())           # 1767225600
```

For API reference see <https://ehsanmok.github.io/tempo>.
"""

from tempo.timestamp import Timestamp
from tempo.duration import Duration
