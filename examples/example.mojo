"""Practical usage examples for the tempo library.

Demonstrates Timestamp creation, formatting, parsing, arithmetic, and
Duration composition.

Run with:

    mojo -I . examples/example.mojo

or via pixi:

    pixi run example
"""

from tempo import Timestamp, Duration


def section(name: String):
    print("\n--- " + name + " ---")


def main() raises:
    print("=" * 60)
    print("tempo library examples")
    print("=" * 60)

    # =========================================================================
    # Current time
    # =========================================================================
    section("Current time")

    var now = Timestamp.now()
    print("now (ISO 8601):  ", now.format_iso8601())
    print("unix seconds:    ", now.unix_secs())
    print("unix ms:         ", now.unix_ms())

    # =========================================================================
    # Constructors
    # =========================================================================
    section("Constructors")

    var epoch = Timestamp.from_unix_secs(0)
    print("Unix epoch:      ", epoch)         # 1970-01-01T00:00:00Z

    var from_ms = Timestamp.from_unix_ms(1_500_000_000_000)
    print("From unix ms:    ", from_ms)       # 2017-07-14T02:40:00Z

    # =========================================================================
    # ISO 8601 parsing
    # =========================================================================
    section("ISO 8601 parsing")

    var parsed = Timestamp.parse_iso8601("2026-01-01T00:00:00Z")
    print("Parsed:          ", parsed)
    print("Unix seconds:    ", parsed.unix_secs())  # 1767225600

    # With fractional seconds.
    var frac = Timestamp.parse_iso8601("2026-04-06T14:30:00.500000Z")
    print("Fractional:      ", frac)
    print("Microseconds:    ", frac.usecs())         # 500000

    # Round-trip check.
    var iso = "2025-06-15T10:45:30Z"
    var t   = Timestamp.parse_iso8601(iso)
    print("Round-trip OK:   ", String(t) == iso)    # True

    # Parsing an invalid string raises.
    print("Parsing invalid string...")
    try:
        _ = Timestamp.parse_iso8601("not-a-date")
    except e:
        print("Parse error (expected):", e)

    # =========================================================================
    # Duration construction
    # =========================================================================
    section("Duration construction")

    var d_secs    = Duration.from_secs(90)
    var d_minutes = Duration.from_minutes(5)
    var d_hours   = Duration.from_hours(2)
    var d_days    = Duration.from_days(3)

    print("90 seconds:      ", d_secs)      # "1m30s"
    print("5 minutes:       ", d_minutes)   # "5m0s"
    print("2 hours:         ", d_hours)     # "2h0m0s"
    print("3 days:          ", d_days)      # "3d0h0m0s"

    # =========================================================================
    # Duration arithmetic
    # =========================================================================
    section("Duration arithmetic")

    var combined = Duration.from_hours(1) + Duration.from_minutes(30) + Duration.from_secs(45)
    print("1h30m45s:        ", combined)     # "1h30m45s"
    print("total seconds:   ", combined.secs())

    var diff = Duration.from_days(1) - Duration.from_hours(6)
    print("1d - 6h:         ", diff)         # "18h0m0s"

    var neg = -Duration.from_hours(2)
    print("Negative:        ", neg)          # "-2h0m0s"
    print("Absolute:        ", neg.abs())    # "2h0m0s"

    # =========================================================================
    # Timestamp arithmetic
    # =========================================================================
    section("Timestamp arithmetic")

    var start   = Timestamp.parse_iso8601("2026-01-01T00:00:00Z")
    var shifted = start.add(Duration.from_days(30))
    print("30 days later:   ", shifted)      # 2026-01-31T00:00:00Z

    var elapsed = shifted.since(start)
    print("Elapsed:         ", elapsed)      # "30d0h0m0s"
    print("Elapsed days:    ", elapsed.days())  # 30

    # =========================================================================
    # Comparison
    # =========================================================================
    section("Comparison")

    var a = Timestamp.from_unix_secs(1000)
    var b = Timestamp.from_unix_secs(2000)
    print("a < b:           ", a < b)    # True
    print("a > b:           ", a > b)    # False
    print("a == a:          ", a == a)   # True
    print("a != b:          ", a != b)   # True

    # =========================================================================
    # Hashing (for use in Dict / Set)
    # =========================================================================
    section("Hashing")

    var h1 = hash(a)
    var h2 = hash(Timestamp.from_unix_secs(1000))
    var h3 = hash(b)
    print("hash(a) == hash(a copy):", h1 == h2)  # True
    print("hash(a) == hash(b):     ", h1 == h3)  # False (very likely)

    print("\n" + "=" * 60)
    print("All examples completed successfully.")
    print("=" * 60)
