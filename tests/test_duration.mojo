"""Tests for the Duration type.

Run with:

    mojo -I . tests/test_duration.mojo

or via pixi:

    pixi run test-duration
"""

from std.testing import assert_equal, assert_true, assert_false
from tempo import Duration


def test_construction_zero() raises:
    var d = Duration()
    assert_equal(d.secs(), 0)


def test_from_secs() raises:
    var d = Duration.from_secs(90)
    assert_equal(d.secs(), 90)


def test_from_minutes() raises:
    var d = Duration.from_minutes(2)
    assert_equal(d.secs(), 120)
    assert_equal(d.minutes(), 2)


def test_from_hours() raises:
    var d = Duration.from_hours(3)
    assert_equal(d.secs(), 10800)
    assert_equal(d.hours(), 3)


def test_from_days() raises:
    var d = Duration.from_days(1)
    assert_equal(d.secs(), 86400)
    assert_equal(d.days(), 1)


def test_days_to_hours() raises:
    var d = Duration.from_days(2)
    assert_equal(d.hours(), 48)


def test_hours_to_minutes() raises:
    var d = Duration.from_hours(2)
    assert_equal(d.minutes(), 120)


def test_minutes_to_secs() raises:
    var d = Duration.from_minutes(3)
    assert_equal(d.secs(), 180)


def test_add() raises:
    var d = Duration.from_hours(1) + Duration.from_minutes(30)
    assert_equal(d.secs(), 5400)


def test_sub() raises:
    var d = Duration.from_hours(2) - Duration.from_hours(1)
    assert_equal(d.hours(), 1)


def test_neg() raises:
    var d = -Duration.from_hours(3)
    assert_equal(d.secs(), -10800)


def test_abs_positive() raises:
    var d = Duration.from_hours(5)
    assert_equal(d.abs().hours(), 5)


def test_abs_negative() raises:
    var d = Duration.from_hours(-3)
    assert_equal(d.abs().hours(), 3)


def test_abs_zero() raises:
    var d = Duration()
    assert_equal(d.abs().secs(), 0)


def test_eq_true() raises:
    var a = Duration.from_hours(1)
    var b = Duration.from_hours(1)
    assert_true(a == b)


def test_eq_false() raises:
    var a = Duration.from_hours(1)
    var b = Duration.from_hours(2)
    assert_false(a == b)


def test_ne() raises:
    var a = Duration.from_secs(1)
    var b = Duration.from_secs(2)
    assert_true(a != b)


def test_lt() raises:
    var a = Duration.from_hours(1)
    var b = Duration.from_hours(2)
    assert_true(a < b)
    assert_false(b < a)


def test_le_equal() raises:
    var a = Duration.from_hours(1)
    var b = Duration.from_hours(1)
    assert_true(a <= b)


def test_le_less() raises:
    var a = Duration.from_hours(1)
    var b = Duration.from_hours(2)
    assert_true(a <= b)


def test_gt() raises:
    var a = Duration.from_hours(3)
    var b = Duration.from_hours(1)
    assert_true(a > b)


def test_ge() raises:
    var a = Duration.from_hours(2)
    var b = Duration.from_hours(2)
    assert_true(a >= b)


def test_str_zero() raises:
    var d = Duration()
    assert_equal(String(d), "0s")


def test_str_seconds_only() raises:
    var d = Duration.from_secs(45)
    assert_equal(String(d), "45s")


def test_str_minutes() raises:
    var d = Duration.from_minutes(5)
    assert_equal(String(d), "5m0s")


def test_str_hours() raises:
    var d = Duration.from_hours(2)
    assert_equal(String(d), "2h0m0s")


def test_str_hours_minutes() raises:
    var d = Duration.from_hours(1) + Duration.from_minutes(30)
    assert_equal(String(d), "1h30m0s")


def test_str_days() raises:
    var d = Duration.from_days(2) + Duration.from_hours(3)
    assert_equal(String(d), "2d3h0m0s")


def test_str_negative() raises:
    var d = -Duration.from_hours(1)
    assert_equal(String(d), "-1h0m0s")


def test_negative_secs_accessor() raises:
    var d = Duration.from_secs(-300)
    assert_equal(d.secs(), -300)
    assert_equal(d.minutes(), -5)


def test_large_duration() raises:
    var d = Duration.from_days(365)
    assert_equal(d.hours(), 8760)


def main() raises:
    test_construction_zero()
    test_from_secs()
    test_from_minutes()
    test_from_hours()
    test_from_days()
    test_days_to_hours()
    test_hours_to_minutes()
    test_minutes_to_secs()
    test_add()
    test_sub()
    test_neg()
    test_abs_positive()
    test_abs_negative()
    test_abs_zero()
    test_eq_true()
    test_eq_false()
    test_ne()
    test_lt()
    test_le_equal()
    test_le_less()
    test_gt()
    test_ge()
    test_str_zero()
    test_str_seconds_only()
    test_str_minutes()
    test_str_hours()
    test_str_hours_minutes()
    test_str_days()
    test_str_negative()
    test_negative_secs_accessor()
    test_large_duration()
    print("All duration tests passed.")
