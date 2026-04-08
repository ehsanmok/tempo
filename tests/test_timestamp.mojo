"""Tests for the Timestamp type.

Run with:

    mojo -I . tests/test_timestamp.mojo

or via pixi:

    pixi run test-timestamp
"""

from std.testing import assert_equal, assert_true, assert_false
from tempo import Timestamp, Duration


def test_from_unix_secs_epoch() raises:
    var t = Timestamp.from_unix_secs(0)
    assert_equal(t.unix_secs(), 0)


def test_from_unix_secs_round_trip() raises:
    var t = Timestamp.from_unix_secs(1_700_000_000)
    assert_equal(t.unix_secs(), 1_700_000_000)


def test_from_unix_ms_basic() raises:
    var t = Timestamp.from_unix_ms(1000)
    assert_equal(t.unix_secs(), 1)
    assert_equal(t.unix_ms(), 1000)


def test_from_unix_ms_sub_second() raises:
    var t = Timestamp.from_unix_ms(1500)
    assert_equal(t.unix_secs(), 1)
    assert_equal(t.unix_ms(), 1500)


def test_from_unix_ms_zero() raises:
    var t = Timestamp.from_unix_ms(0)
    assert_equal(t.unix_ms(), 0)
    assert_equal(t.unix_secs(), 0)


def test_unix_ms_consistency() raises:
    var secs: Int64 = 1_700_000_000
    var t = Timestamp.from_unix_secs(secs)
    assert_equal(t.unix_ms(), secs * 1000)


def test_format_epoch() raises:
    var t = Timestamp.from_unix_secs(0)
    assert_equal(t.format_iso8601(), "1970-01-01T00:00:00Z")


def test_format_known_date() raises:
    # 2026-01-01T00:00:00Z == 1767225600 Unix seconds.
    var t = Timestamp.from_unix_secs(1_767_225_600)
    assert_equal(t.format_iso8601(), "2026-01-01T00:00:00Z")


def test_format_with_time() raises:
    # 2026-04-06T14:30:00Z
    # days from epoch to 2026-04-06:
    # 2026-04-06: 56 years + leap days + ...
    # Let's just use parse+format round-trip.
    var iso = "2026-04-06T14:30:00Z"
    var t = Timestamp.parse_iso8601(iso)
    assert_equal(t.format_iso8601(), iso)


def test_format_with_microseconds() raises:
    var t = Timestamp(1_767_225_600, 500_000)
    var s = t.format_iso8601()
    assert_equal(s, "2026-01-01T00:00:00.500000Z")


def test_parse_epoch() raises:
    var t = Timestamp.parse_iso8601("1970-01-01T00:00:00Z")
    assert_equal(t.unix_secs(), 0)


def test_parse_known_date() raises:
    var t = Timestamp.parse_iso8601("2026-01-01T00:00:00Z")
    assert_equal(t.unix_secs(), 1_767_225_600)


def test_parse_with_time_components() raises:
    # 1 hour = 3600 seconds after epoch
    var t = Timestamp.parse_iso8601("1970-01-01T01:00:00Z")
    assert_equal(t.unix_secs(), 3600)


def test_parse_round_trip() raises:
    var iso = "2025-06-15T10:45:30Z"
    var t = Timestamp.parse_iso8601(iso)
    assert_equal(t.format_iso8601(), iso)


def test_parse_with_fractional_seconds() raises:
    var iso = "2026-01-01T00:00:00.123456Z"
    var t = Timestamp.parse_iso8601(iso)
    assert_equal(t.usecs(), 123456)
    assert_equal(t.format_iso8601(), iso)


def test_parse_fractional_3_digits() raises:
    # "2026-01-01T00:00:00.100Z" -> 100000 us
    var t = Timestamp.parse_iso8601("2026-01-01T00:00:00.100Z")
    assert_equal(t.usecs(), 100000)


def test_parse_no_tz_suffix() raises:
    # No 'Z' suffix: treat as UTC.
    var t = Timestamp.parse_iso8601("1970-01-01T00:00:00")
    assert_equal(t.unix_secs(), 0)


def test_parse_invalid_short_raises() raises:
    var raised = False
    try:
        _ = Timestamp.parse_iso8601("2026-01")
    except:
        raised = True
    assert_true(raised)


def test_add_duration() raises:
    var t = Timestamp.from_unix_secs(0)
    var later = t.add(Duration.from_hours(1))
    assert_equal(later.unix_secs(), 3600)


def test_add_days() raises:
    var t = Timestamp.from_unix_secs(0)
    var d = t.add(Duration.from_days(1))
    assert_equal(d.unix_secs(), 86400)


def test_since_forward() raises:
    var a = Timestamp.from_unix_secs(0)
    var b = Timestamp.from_unix_secs(7200)
    assert_equal(b.since(a).hours(), 2)


def test_since_backward() raises:
    var a = Timestamp.from_unix_secs(3600)
    var b = Timestamp.from_unix_secs(0)
    assert_equal(b.since(a).secs(), -3600)


def test_since_zero() raises:
    var t = Timestamp.from_unix_secs(1000)
    assert_equal(t.since(t).secs(), 0)


def test_eq_true() raises:
    var a = Timestamp.from_unix_secs(1000)
    var b = Timestamp.from_unix_secs(1000)
    assert_true(a == b)


def test_eq_false() raises:
    var a = Timestamp.from_unix_secs(1000)
    var b = Timestamp.from_unix_secs(2000)
    assert_false(a == b)


def test_ne() raises:
    var a = Timestamp.from_unix_secs(1)
    var b = Timestamp.from_unix_secs(2)
    assert_true(a != b)


def test_lt() raises:
    var a = Timestamp.from_unix_secs(1)
    var b = Timestamp.from_unix_secs(2)
    assert_true(a < b)
    assert_false(b < a)


def test_le() raises:
    var a = Timestamp.from_unix_secs(1)
    var b = Timestamp.from_unix_secs(1)
    assert_true(a <= b)


def test_gt() raises:
    var a = Timestamp.from_unix_secs(2)
    var b = Timestamp.from_unix_secs(1)
    assert_true(a > b)


def test_ge() raises:
    var a = Timestamp.from_unix_secs(2)
    var b = Timestamp.from_unix_secs(2)
    assert_true(a >= b)


def test_hash_equal_values() raises:
    var a = Timestamp.from_unix_secs(12345)
    var b = Timestamp.from_unix_secs(12345)
    assert_equal(hash(a), hash(b))


def test_str() raises:
    var t = Timestamp.from_unix_secs(0)
    assert_equal(String(t), "1970-01-01T00:00:00Z")


def test_now_is_reasonable() raises:
    # Timestamp.now() should return something after 2020-01-01.
    var t = Timestamp.now()
    # 2020-01-01T00:00:00Z = 1577836800
    assert_true(t.unix_secs() > 1_577_836_800)


def test_add_then_since_round_trip() raises:
    var t = Timestamp.from_unix_secs(1_000_000)
    var d = Duration.from_hours(3)
    var later = t.add(d)
    assert_equal(later.since(t).secs(), d.secs())


def main() raises:
    test_from_unix_secs_epoch()
    test_from_unix_secs_round_trip()
    test_from_unix_ms_basic()
    test_from_unix_ms_sub_second()
    test_from_unix_ms_zero()
    test_unix_ms_consistency()
    test_format_epoch()
    test_format_known_date()
    test_format_with_time()
    test_format_with_microseconds()
    test_parse_epoch()
    test_parse_known_date()
    test_parse_with_time_components()
    test_parse_round_trip()
    test_parse_with_fractional_seconds()
    test_parse_fractional_3_digits()
    test_parse_no_tz_suffix()
    test_parse_invalid_short_raises()
    test_add_duration()
    test_add_days()
    test_since_forward()
    test_since_backward()
    test_since_zero()
    test_eq_true()
    test_eq_false()
    test_ne()
    test_lt()
    test_le()
    test_gt()
    test_ge()
    test_hash_equal_values()
    test_str()
    test_now_is_reasonable()
    test_add_then_since_round_trip()
    print("All timestamp tests passed.")
