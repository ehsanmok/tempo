"""Throughput benchmarks for the tempo library.

Measures performance of Timestamp creation, parsing, formatting, and
Duration arithmetic using the standard `std.benchmark` harness.

Run with:

    mojo -I . benchmark/bench.mojo

or via pixi:

    pixi run bench

Expected throughput targets on a modern CPU:

    | Operation                   | Target    |
    |-----------------------------|-----------|
    | Timestamp.now()             | < 200 ns  |
    | Timestamp.from_unix_secs()  | < 5 ns    |
    | Timestamp.parse_iso8601()   | < 300 ns  |
    | Timestamp.format_iso8601()  | < 200 ns  |
    | Duration.from_hours()       | < 5 ns    |
    | Duration arithmetic (+)     | < 5 ns    |
    | t.add(d)                    | < 10 ns   |
    | t.since(t2)                 | < 10 ns   |
"""

from std.benchmark import Bench, BenchConfig, BenchId, keep, clobber_memory
from tempo import Timestamp, Duration

comptime KNOWN_ISO = "2026-04-06T14:30:00Z"


def main() raises:
    var bench = Bench(BenchConfig(max_iters=10_000))

    # =========================================================================
    # Timestamp.now()
    # =========================================================================

    @parameter
    @always_inline
    def bench_now() raises:
        var t = Timestamp.now()
        keep(t._secs)

    bench.bench_function[bench_now](BenchId("create", "Timestamp.now"))

    # =========================================================================
    # Timestamp.from_unix_secs()
    # =========================================================================

    @parameter
    @always_inline
    def bench_from_secs() raises:
        clobber_memory()
        var t = Timestamp.from_unix_secs(1_767_225_600)
        keep(t._secs)

    bench.bench_function[bench_from_secs](BenchId("create", "from_unix_secs"))

    # =========================================================================
    # Timestamp.parse_iso8601()
    # =========================================================================

    @parameter
    @always_inline
    def bench_parse() raises:
        clobber_memory()
        var t = Timestamp.parse_iso8601(KNOWN_ISO)
        keep(t._secs)

    bench.bench_function[bench_parse](BenchId("parse", "parse_iso8601"))

    # =========================================================================
    # Timestamp.format_iso8601()
    # =========================================================================

    var fmt_ts = Timestamp.from_unix_secs(1_767_225_600)

    @parameter
    @always_inline
    def bench_format() raises:
        clobber_memory()
        var s = fmt_ts.format_iso8601()
        keep(s.as_bytes().unsafe_ptr())

    bench.bench_function[bench_format](BenchId("format", "format_iso8601"))

    # =========================================================================
    # Duration.from_hours()
    # =========================================================================

    @parameter
    @always_inline
    def bench_dur_from_hours() raises:
        clobber_memory()
        var d = Duration.from_hours(2)
        keep(d._secs)

    bench.bench_function[bench_dur_from_hours](BenchId("create", "Duration.from_hours"))

    # =========================================================================
    # Duration addition
    # =========================================================================

    var da = Duration.from_hours(1)
    var db = Duration.from_minutes(30)

    @parameter
    @always_inline
    def bench_dur_add() raises:
        clobber_memory()
        var d = da + db
        keep(d._secs)

    bench.bench_function[bench_dur_add](BenchId("arithmetic", "Duration.__add__"))

    # =========================================================================
    # Timestamp.add(Duration)
    # =========================================================================

    var base_ts = Timestamp.from_unix_secs(1_767_225_600)
    var shift    = Duration.from_days(1)

    @parameter
    @always_inline
    def bench_ts_add() raises:
        clobber_memory()
        var t = base_ts.add(shift)
        keep(t._secs)

    bench.bench_function[bench_ts_add](BenchId("arithmetic", "Timestamp.add"))

    # =========================================================================
    # Timestamp.since()
    # =========================================================================

    var ts_a = Timestamp.from_unix_secs(1_767_225_600)
    var ts_b = Timestamp.from_unix_secs(1_767_312_000)

    @parameter
    @always_inline
    def bench_since() raises:
        clobber_memory()
        var d = ts_b.since(ts_a)
        keep(d._secs)

    bench.bench_function[bench_since](BenchId("arithmetic", "Timestamp.since"))

    print(bench)
