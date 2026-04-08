"""Signed duration type for representing spans of time.

`Duration` stores a signed number of seconds as `Int64`, giving a range of
roughly ±292 billion years — more than sufficient for any practical timestamp
arithmetic.

All factory methods are named `from_*` so the unit is always explicit at the
call site. Arithmetic operators (`+`, `-`, negation) preserve the sign, and
`abs()` returns the magnitude regardless of direction.

Example:

    from tempo import Duration

    var d = Duration.from_hours(2) + Duration.from_minutes(30)
    print(d)  # "2h30m0s"

    var neg = -d
    print(neg.abs())  # "2h30m0s"
"""


struct Duration(Copyable, Movable, Writable):
    """A signed duration stored as a whole number of seconds.

    Use the `from_*` class methods to construct a `Duration` with an explicit
    unit. Arithmetic operations (`+`, `-`, unary `-`) are all defined. The
    `__str__` representation omits zero-valued components except the trailing
    seconds component:

        "0s"          # zero
        "45s"         # less than a minute
        "5m0s"        # exact minutes
        "1h30m0s"     # hours + minutes
        "2d3h0m0s"    # days + hours + minutes

    Example:

        var d = Duration.from_hours(1) + Duration.from_minutes(30)
        print(d)         # "1h30m0s"
        print(d.secs())  # 5400
    """

    var _secs: Int64
    """Total signed duration in seconds."""

    @always_inline
    def __init__(out self, secs: Int64 = 0):
        """Construct a Duration directly from a signed second count.

        Args:
            secs: Signed number of seconds. Negative values represent
                durations in the past.
        """
        self._secs = secs

    # -------------------------------------------------------------------------
    # Factory methods
    # -------------------------------------------------------------------------

    @staticmethod
    @always_inline
    def from_secs(n: Int64) -> Duration:
        """Construct a Duration from a number of seconds.

        Args:
            n: Number of seconds (may be negative).

        Returns:
            A Duration equal to `n` seconds.

        Example:

            var d = Duration.from_secs(90)
            print(d.minutes())  # 1
        """
        return Duration(n)

    @staticmethod
    @always_inline
    def from_minutes(n: Int64) -> Duration:
        """Construct a Duration from a number of minutes.

        Args:
            n: Number of minutes (may be negative).

        Returns:
            A Duration equal to `n * 60` seconds.

        Example:

            var d = Duration.from_minutes(90)
            print(d.hours())  # 1
        """
        return Duration(n * 60)

    @staticmethod
    @always_inline
    def from_hours(n: Int64) -> Duration:
        """Construct a Duration from a number of hours.

        Args:
            n: Number of hours (may be negative).

        Returns:
            A Duration equal to `n * 3600` seconds.

        Example:

            var d = Duration.from_hours(24)
            print(d.days())  # 1
        """
        return Duration(n * 3600)

    @staticmethod
    @always_inline
    def from_days(n: Int64) -> Duration:
        """Construct a Duration from a number of days.

        Args:
            n: Number of days (may be negative).

        Returns:
            A Duration equal to `n * 86400` seconds.

        Example:

            var d = Duration.from_days(7)
            print(d.hours())  # 168
        """
        return Duration(n * 86400)

    # -------------------------------------------------------------------------
    # Accessors
    # -------------------------------------------------------------------------

    @always_inline
    def secs(self) -> Int64:
        """Return the total duration in whole seconds (signed).

        Returns:
            Signed number of seconds.

        Example:

            print(Duration.from_minutes(2).secs())  # 120
        """
        return self._secs

    @always_inline
    def minutes(self) -> Int64:
        """Return the total duration in whole minutes (truncated, signed).

        Returns:
            Signed number of whole minutes.

        Example:

            print(Duration.from_secs(90).minutes())  # 1
        """
        return self._secs // 60

    @always_inline
    def hours(self) -> Int64:
        """Return the total duration in whole hours (truncated, signed).

        Returns:
            Signed number of whole hours.

        Example:

            print(Duration.from_minutes(90).hours())  # 1
        """
        return self._secs // 3600

    @always_inline
    def days(self) -> Int64:
        """Return the total duration in whole days (truncated, signed).

        Returns:
            Signed number of whole days.

        Example:

            print(Duration.from_hours(48).days())  # 2
        """
        return self._secs // 86400

    @always_inline
    def abs(self) -> Duration:
        """Return a new Duration with the absolute value (non-negative).

        Returns:
            A Duration whose `secs()` is >= 0.

        Example:

            var neg = Duration.from_hours(-3)
            print(neg.abs().hours())  # 3
        """
        if self._secs < 0:
            return Duration(-self._secs)
        return Duration(self._secs)

    # -------------------------------------------------------------------------
    # Arithmetic
    # -------------------------------------------------------------------------

    @always_inline
    def __add__(self, other: Duration) -> Duration:
        """Add two durations.

        Args:
            other: The duration to add.

        Returns:
            A new Duration equal to `self + other`.

        Example:

            var d = Duration.from_hours(1) + Duration.from_minutes(30)
            print(d.secs())  # 5400
        """
        return Duration(self._secs + other._secs)

    @always_inline
    def __sub__(self, other: Duration) -> Duration:
        """Subtract a duration.

        Args:
            other: The duration to subtract.

        Returns:
            A new Duration equal to `self - other`.

        Example:

            var d = Duration.from_hours(2) - Duration.from_hours(1)
            print(d.hours())  # 1
        """
        return Duration(self._secs - other._secs)

    @always_inline
    def __neg__(self) -> Duration:
        """Negate the duration.

        Returns:
            A new Duration with the sign flipped.

        Example:

            var neg = -Duration.from_hours(3)
            print(neg.secs())  # -10800
        """
        return Duration(-self._secs)

    # -------------------------------------------------------------------------
    # Comparison
    # -------------------------------------------------------------------------

    @always_inline
    def __eq__(self, other: Duration) -> Bool:
        """Return True if both durations are equal.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs == other._secs`.
        """
        return self._secs == other._secs

    @always_inline
    def __ne__(self, other: Duration) -> Bool:
        """Return True if the durations differ.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs != other._secs`.
        """
        return self._secs != other._secs

    @always_inline
    def __lt__(self, other: Duration) -> Bool:
        """Return True if this duration is shorter than `other`.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs < other._secs`.
        """
        return self._secs < other._secs

    @always_inline
    def __le__(self, other: Duration) -> Bool:
        """Return True if this duration is at most `other`.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs <= other._secs`.
        """
        return self._secs <= other._secs

    @always_inline
    def __gt__(self, other: Duration) -> Bool:
        """Return True if this duration is longer than `other`.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs > other._secs`.
        """
        return self._secs > other._secs

    @always_inline
    def __ge__(self, other: Duration) -> Bool:
        """Return True if this duration is at least `other`.

        Args:
            other: Duration to compare.

        Returns:
            True if `self._secs >= other._secs`.
        """
        return self._secs >= other._secs

    # -------------------------------------------------------------------------
    # Formatting
    # -------------------------------------------------------------------------

    def write_to[W: Writer](self, mut writer: W):
        """Write a human-readable representation of the duration.

        Format: `[Nd][Nh][Nm]Ns` where zero-valued leading components are
        omitted, but seconds are always included. A negative duration is
        prefixed with `-`.

        Examples: `"0s"`, `"45s"`, `"5m0s"`, `"1h30m0s"`, `"2d3h0m0s"`.

        Parameters:
            W: A type implementing the `Writer` trait.

        Args:
            writer: The writer to write to.
        """
        var total = self._secs
        if total < 0:
            writer.write("-")
            total = -total

        var d = total // 86400
        var rem = total % 86400
        var h = rem // 3600
        rem = rem % 3600
        var m = rem // 60
        var s = rem % 60

        if d > 0:
            writer.write(String(d) + "d")
        if h > 0 or d > 0:
            writer.write(String(h) + "h")
        if m > 0 or h > 0 or d > 0:
            writer.write(String(m) + "m")
        writer.write(String(s) + "s")

    def __str__(self) -> String:
        """Return a human-readable string representation of the duration.

        Returns:
            A string like `"0s"`, `"45s"`, `"1h30m0s"`, `"2d3h0m0s"`.

        Example:

            print(Duration.from_hours(2) + Duration.from_minutes(30))  # "2h30m0s"
        """
        return String.write(self)
