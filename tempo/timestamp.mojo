"""UTC timestamp with microsecond resolution and ISO 8601 support.

`Timestamp` stores a POSIX time as a pair of (seconds, microseconds) and
exposes the full Unix epoch integer interface alongside ISO 8601
formatting and parsing. All operations are UTC.

The current time is obtained via a single `gettimeofday(2)` libc call.
All calendar arithmetic uses the Gregorian civil-calendar algorithm by
Howard Hinnant (public domain, see <https://howardhinnant.github.io/date_algorithms.html>).
No additional FFI is required beyond the one `gettimeofday` call.

Example:

    from tempo import Timestamp, Duration

    var t = Timestamp.now()
    print(t.format_iso8601())  # "2026-04-06T14:30:00Z"

    var later = t.add(Duration.from_hours(2))
    var elapsed = later.since(t)
    print(elapsed.hours())     # 2
"""

from std.ffi import external_call
from tempo.duration import Duration


# ---------------------------------------------------------------------------
# FFI helpers
# ---------------------------------------------------------------------------


struct _Timeval:
    """POSIX `timeval` structure for `gettimeofday(2)`."""

    var tv_sec: Int64
    """Seconds since the Unix epoch (1970-01-01T00:00:00Z)."""

    var tv_usec: Int64
    """Microseconds component [0, 999999]."""

    def __init__(out self):
        self.tv_sec = 0
        self.tv_usec = 0


@always_inline
def _get_time() -> Tuple[Int64, Int32]:
    """Call `gettimeofday` and return (seconds, microseconds).

    Returns:
        A tuple `(tv_sec, tv_usec)` representing the current UTC time.
    """
    var tv = _Timeval()
    _ = external_call["gettimeofday", Int32](UnsafePointer(to=tv), Int64(0))
    return (tv.tv_sec, Int32(tv.tv_usec))


# ---------------------------------------------------------------------------
# Gregorian calendar helpers (Howard Hinnant, public domain)
# ---------------------------------------------------------------------------


@always_inline
def _days_to_ymd(days: Int64) -> Tuple[Int64, Int64, Int64]:
    """Convert days since the Unix epoch to a Gregorian (year, month, day).

    Uses Howard Hinnant's civil-calendar algorithm.

    Args:
        days: Signed days since 1970-01-01.

    Returns:
        A tuple `(year, month, day)` where `month` is in [1, 12] and
        `day` is in [1, 31].
    """
    var z = days + 719468
    var era: Int64
    if z >= 0:
        era = z // 146097
    else:
        era = (z - 146096) // 146097
    var doe = z - era * 146097
    var yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
    var y = yoe + era * 400
    var doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
    var mp = (5 * doy + 2) // 153
    var d = doy - (153 * mp + 2) // 5 + 1
    var m: Int64
    if mp < 10:
        m = mp + 3
    else:
        m = mp - 9
    if m <= 2:
        y += 1
    return (y, m, d)


@always_inline
def _ymd_to_days(year: Int64, month: Int64, day: Int64) -> Int64:
    """Convert a Gregorian (year, month, day) to days since the Unix epoch.

    Uses Howard Hinnant's civil-calendar algorithm.

    Args:
        year: Proleptic Gregorian year (e.g. 2026).
        month: Month in [1, 12].
        day: Day of month in [1, 31].

    Returns:
        Signed number of days since 1970-01-01.
    """
    var y = year
    var m = month
    if m >= 3:
        m -= 3
    else:
        m += 9
        y -= 1
    var era: Int64
    if y >= 0:
        era = y // 400
    else:
        era = (y - 399) // 400
    var yoe = y - era * 400
    var doy = (153 * m + 2) // 5 + day - 1
    var doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468


@always_inline
def _pad2(n: Int64) -> String:
    """Return `n` as a zero-padded two-digit string.

    Args:
        n: A non-negative integer in [0, 99].

    Returns:
        A string of exactly two decimal digits.
    """
    if n < 10:
        return "0" + String(n)
    return String(n)


@always_inline
def _pad4(n: Int64) -> String:
    """Return `n` as a zero-padded four-digit string.

    Args:
        n: A non-negative integer in [0, 9999].

    Returns:
        A string of at least four decimal digits, zero-padded on the left.
    """
    if n < 10:
        return "000" + String(n)
    if n < 100:
        return "00" + String(n)
    if n < 1000:
        return "0" + String(n)
    return String(n)


@always_inline
def _pad6(n: Int64) -> String:
    """Return `n` as a zero-padded six-digit string.

    Args:
        n: A non-negative integer in [0, 999999].

    Returns:
        A string of exactly six decimal digits.
    """
    if n < 10:
        return "00000" + String(n)
    if n < 100:
        return "0000" + String(n)
    if n < 1000:
        return "000" + String(n)
    if n < 10000:
        return "00" + String(n)
    if n < 100000:
        return "0" + String(n)
    return String(n)


@always_inline
def _parse_int(s: String, start: Int, end: Int) raises -> Int64:
    """Parse a decimal integer from a substring of `s`.

    Args:
        s: The source string.
        start: Start index (inclusive).
        end: End index (exclusive).

    Returns:
        The parsed integer value.

    Raises:
        Error: If any character is not a decimal digit.
    """
    var result: Int64 = 0
    var i = start
    while i < end:
        var c = Int64(s.as_bytes()[i]) - 48  # ord('0') == 48
        if c < 0 or c > 9:
            raise Error("tempo: expected digit at position " + String(i))
        result = result * 10 + c
        i += 1
    return result


# ---------------------------------------------------------------------------
# Timestamp struct
# ---------------------------------------------------------------------------


struct Timestamp(Copyable, Movable, Writable, Hashable):
    """A UTC timestamp with microsecond resolution.

    Internally stores (Unix seconds, microseconds) as `(Int64, Int32)`.
    All methods treat the value as UTC. The range covers the full POSIX
    timestamp domain (roughly 292 billion years from the epoch).

    Example:

        var t = Timestamp.now()
        print(t.format_iso8601())      # "2026-04-06T14:30:00Z"
        var later = t.add(Duration.from_days(1))
        print(later.since(t).hours())  # 24
    """

    var _secs: Int64
    """Seconds since 1970-01-01T00:00:00Z."""

    var _usecs: Int32
    """Microseconds component in [0, 999999]."""

    @always_inline
    def __init__(out self, secs: Int64 = 0, usecs: Int32 = 0):
        """Construct a Timestamp from raw (seconds, microseconds) components.

        Args:
            secs: Seconds since the Unix epoch (may be negative).
            usecs: Microseconds component in [0, 999999].
        """
        self._secs = secs
        self._usecs = usecs

    # -------------------------------------------------------------------------
    # Factory methods
    # -------------------------------------------------------------------------

    @staticmethod
    def now() -> Timestamp:
        """Return the current UTC time obtained via `gettimeofday(2)`.

        Returns:
            A Timestamp representing the current wall-clock time in UTC.

        Example:

            var t = Timestamp.now()
            print(t.unix_secs())  # e.g. 1775400000
        """
        var tv = _get_time()
        return Timestamp(tv[0], tv[1])

    @staticmethod
    @always_inline
    def from_unix_secs(s: Int64) -> Timestamp:
        """Construct a Timestamp from a Unix second count.

        Args:
            s: Seconds since 1970-01-01T00:00:00Z.

        Returns:
            A Timestamp with zero microseconds.

        Example:

            var t = Timestamp.from_unix_secs(0)
            print(t.format_iso8601())  # "1970-01-01T00:00:00Z"
        """
        return Timestamp(s, 0)

    @staticmethod
    @always_inline
    def from_unix_ms(ms: Int64) -> Timestamp:
        """Construct a Timestamp from a Unix millisecond count.

        Args:
            ms: Milliseconds since 1970-01-01T00:00:00Z.

        Returns:
            A Timestamp with sub-second microseconds preserved.

        Example:

            var t = Timestamp.from_unix_ms(1000)
            print(t.unix_secs())  # 1
        """
        var s = ms // 1000
        var us = Int32((ms % 1000) * 1000)
        return Timestamp(s, us)

    @staticmethod
    def parse_iso8601(s: String) raises -> Timestamp:
        """Parse an ISO 8601 UTC timestamp string.

        Accepted formats:
            - `"YYYY-MM-DDTHH:MM:SSZ"`
            - `"YYYY-MM-DDTHH:MM:SS.ffffffZ"`
            - `"YYYY-MM-DDTHH:MM:SS"` (no timezone suffix, assumed UTC)

        Args:
            s: An ISO 8601 timestamp string.

        Returns:
            A Timestamp representing the given UTC time.

        Raises:
            Error: If the string is malformed or contains an out-of-range
                component.

        Example:

            var t = Timestamp.parse_iso8601("2026-04-06T14:30:00Z")
            print(t.unix_secs())  # 1775471400
        """
        var n = len(s)
        if n < 19:
            raise Error("tempo: ISO 8601 string too short: " + s)

        var year  = _parse_int(s, 0, 4)
        var month = _parse_int(s, 5, 7)
        var day   = _parse_int(s, 8, 10)
        var hour  = _parse_int(s, 11, 13)
        var minute = _parse_int(s, 14, 16)
        var sec   = _parse_int(s, 17, 19)

        # Validate ranges.
        if month < 1 or month > 12:
            raise Error("tempo: month out of range: " + String(month))
        if day < 1 or day > 31:
            raise Error("tempo: day out of range: " + String(day))
        if hour > 23:
            raise Error("tempo: hour out of range: " + String(hour))
        if minute > 59:
            raise Error("tempo: minute out of range: " + String(minute))
        if sec > 60:
            raise Error("tempo: second out of range: " + String(sec))

        var days = _ymd_to_days(year, month, day)
        var total_secs = days * 86400 + hour * 3600 + minute * 60 + sec

        # Parse optional fractional seconds: ".ffffff"
        var usecs: Int32 = 0
        if n > 19 and Int(s.as_bytes()[19]) == 46:  # ord('.') == 46
            # Read up to 6 fractional digits.
            var frac_start = 20
            var frac_end = frac_start
            while frac_end < n and frac_end - frac_start < 6:
                var c = Int(s.as_bytes()[frac_end]) - 48
                if c < 0 or c > 9:
                    break
                frac_end += 1
            var frac_digits = frac_end - frac_start
            var frac = _parse_int(s, frac_start, frac_end)
            # Scale to microseconds (6 digits).
            var scale: Int64 = 1
            for _ in range(6 - frac_digits):
                scale *= 10
            usecs = Int32(frac * scale)

        return Timestamp(total_secs, usecs)

    # -------------------------------------------------------------------------
    # Accessors
    # -------------------------------------------------------------------------

    @always_inline
    def unix_secs(self) -> Int64:
        """Return the Unix timestamp in whole seconds.

        Returns:
            Seconds since 1970-01-01T00:00:00Z.

        Example:

            print(Timestamp.from_unix_secs(3600).unix_secs())  # 3600
        """
        return self._secs

    @always_inline
    def unix_ms(self) -> Int64:
        """Return the Unix timestamp in milliseconds.

        Returns:
            Milliseconds since 1970-01-01T00:00:00Z.

        Example:

            print(Timestamp.from_unix_ms(1500).unix_ms())  # 1500
        """
        return self._secs * 1000 + Int64(self._usecs) // 1000

    @always_inline
    def usecs(self) -> Int32:
        """Return the sub-second microseconds component.

        Returns:
            Microseconds in [0, 999999].

        Example:

            var t = Timestamp.from_unix_ms(1001)
            print(t.usecs())  # 1000
        """
        return self._usecs

    # -------------------------------------------------------------------------
    # Arithmetic
    # -------------------------------------------------------------------------

    def add(self, d: Duration) -> Timestamp:
        """Return a new Timestamp shifted forward by a Duration.

        Negative durations shift backwards.

        Args:
            d: The Duration to add.

        Returns:
            A new Timestamp equal to `self + d`.

        Example:

            var t = Timestamp.from_unix_secs(0)
            var later = t.add(Duration.from_hours(1))
            print(later.unix_secs())  # 3600
        """
        return Timestamp(self._secs + d.secs(), self._usecs)

    def since(self, earlier: Timestamp) -> Duration:
        """Return the Duration from `earlier` to `self`.

        A positive result means `self` is after `earlier`; a negative
        result means `self` is before `earlier`.

        Microsecond components are ignored; only whole seconds are compared.

        Args:
            earlier: The reference Timestamp.

        Returns:
            A Duration equal to `self - earlier` in whole seconds.

        Example:

            var a = Timestamp.from_unix_secs(0)
            var b = Timestamp.from_unix_secs(7200)
            print(b.since(a).hours())  # 2
        """
        return Duration(self._secs - earlier._secs)

    # -------------------------------------------------------------------------
    # ISO 8601 formatting
    # -------------------------------------------------------------------------

    def format_iso8601(self) -> String:
        """Format the timestamp as an ISO 8601 UTC string.

        Produces `"YYYY-MM-DDTHH:MM:SSZ"` when microseconds are zero, or
        `"YYYY-MM-DDTHH:MM:SS.ffffffZ"` when they are non-zero.

        Returns:
            An ISO 8601 UTC string.

        Example:

            var t = Timestamp.from_unix_secs(0)
            print(t.format_iso8601())  # "1970-01-01T00:00:00Z"
        """
        var days = self._secs // 86400
        var time_secs = self._secs % 86400
        if time_secs < 0:
            days -= 1
            time_secs += 86400

        var ymd = _days_to_ymd(days)
        var yy = ymd[0]
        var mm = ymd[1]
        var dd = ymd[2]
        var h = time_secs // 3600
        var rem = time_secs % 3600
        var mi = rem // 60
        var s = rem % 60

        var base = _pad4(yy) + "-" + _pad2(mm) + "-" + _pad2(dd) + "T" + _pad2(h) + ":" + _pad2(mi) + ":" + _pad2(s)
        if self._usecs != 0:
            return base + "." + _pad6(Int64(self._usecs)) + "Z"
        return base + "Z"

    # -------------------------------------------------------------------------
    # Comparison
    # -------------------------------------------------------------------------

    @always_inline
    def __eq__(self, other: Timestamp) -> Bool:
        """Return True if both timestamps represent the same instant.

        Args:
            other: Timestamp to compare.

        Returns:
            True if seconds and microseconds are equal.
        """
        return self._secs == other._secs and self._usecs == other._usecs

    @always_inline
    def __ne__(self, other: Timestamp) -> Bool:
        """Return True if the timestamps differ.

        Args:
            other: Timestamp to compare.

        Returns:
            True if seconds or microseconds differ.
        """
        return self._secs != other._secs or self._usecs != other._usecs

    @always_inline
    def __lt__(self, other: Timestamp) -> Bool:
        """Return True if `self` is before `other`.

        Args:
            other: Timestamp to compare.

        Returns:
            True if `self` occurs strictly before `other`.
        """
        if self._secs != other._secs:
            return self._secs < other._secs
        return self._usecs < other._usecs

    @always_inline
    def __le__(self, other: Timestamp) -> Bool:
        """Return True if `self` is at or before `other`.

        Args:
            other: Timestamp to compare.

        Returns:
            True if `self` occurs at or before `other`.
        """
        if self._secs != other._secs:
            return self._secs < other._secs
        return self._usecs <= other._usecs

    @always_inline
    def __gt__(self, other: Timestamp) -> Bool:
        """Return True if `self` is after `other`.

        Args:
            other: Timestamp to compare.

        Returns:
            True if `self` occurs strictly after `other`.
        """
        if self._secs != other._secs:
            return self._secs > other._secs
        return self._usecs > other._usecs

    @always_inline
    def __ge__(self, other: Timestamp) -> Bool:
        """Return True if `self` is at or after `other`.

        Args:
            other: Timestamp to compare.

        Returns:
            True if `self` occurs at or after `other`.
        """
        if self._secs != other._secs:
            return self._secs > other._secs
        return self._usecs >= other._usecs

    # -------------------------------------------------------------------------
    # Hashing
    # -------------------------------------------------------------------------

    def __hash__(self) -> UInt:
        """Return a hash of this Timestamp.

        Combines the seconds and microseconds fields using a simple
        multiplicative mix.

        Returns:
            A hash value suitable for use in collections.
        """
        # FNV-1a over the 12 bytes of (secs, usecs).
        var h: UInt = 14695981039346656037
        var s = self._secs
        for _ in range(8):
            h ^= UInt(Int(s & 0xFF))
            h *= UInt(1099511628211)
            s >>= 8
        var u = self._usecs
        for _ in range(4):
            h ^= UInt(Int(u & 0xFF))
            h *= UInt(1099511628211)
            u >>= 8
        return h

    # -------------------------------------------------------------------------
    # Formatting
    # -------------------------------------------------------------------------

    def write_to[W: Writer](self, mut writer: W):
        """Write the ISO 8601 UTC representation to a writer.

        Parameters:
            W: A type implementing the `Writer` trait.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.format_iso8601())

    def __str__(self) -> String:
        """Return the ISO 8601 UTC string representation.

        Returns:
            A string like `"2026-04-06T14:30:00Z"`.

        Example:

            var t = Timestamp.from_unix_secs(0)
            print(t)  # "1970-01-01T00:00:00Z"
        """
        return self.format_iso8601()
