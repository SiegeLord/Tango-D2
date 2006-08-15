/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.Interval;

public import tango.sys.OS;
public import tango.stdc.time;

version (Posix)
    public import tango.stdc.posix.time;


/** Constants used in time unit conversion */
private const ulong SecToUsec  = 1_000_000UL;
private const ulong MsecToUsec = 1_000UL;
private const ulong USecToNsec = 1_000UL;


/**
 * Time interval with microsecond precision.
 *
 * Examples:
 * ---
 * Interval i1, i2, i3;
 *
 * i1 = Interval(120, 0);
 * i2 = Sec(30);
 * i3 = i1 + i2;
 * i3 *= 2;
 *
 * // The following assertion should be true:
 * assert(i3 == Sec(300));
 * ---
 */
struct Interval
{
    public static const Interval min;
    public static const Interval max;
    alias min zero;
    alias max infinity;

    private ulong _usec = 0UL;

    static this()
    {
        min = Interval(ulong.min);
        max = Interval(ulong.max);
    }

    version (Win32)
    {
        // Static constant to remove time skew between the Windows FILETIME
        // and POSIX time. POSIX and Win32 use different epochs
        // (Jan. 1, 1970 v.s. Jan. 1, 1601). The following constant defines
        // the difference in 100ns ticks.
        // private static const ulong FiletimeToUsecSkew = 0x19db1ded53e8000;
        private static const ulong FiletimeToUsecSkew;

        static this()
        {
            SYSTEMTIME stime;
            FILETIME   ftime;

            // First second of 1970 (Unix epoch)
            stime.wYear = 1970;
            stime.wMonth = 1;
            stime.wDayOfWeek = 0;
            stime.wDay = 1;
            stime.wHour = 0;
            stime.wMinute = 0;
            stime.wSecond = 0;
            stime.wMilliseconds = 0;
            SystemTimeToFileTime(&stime, &ftime);

            FiletimeToUsecSkew = (cast(ulong) ftime.dwHighDateTime) << 32 |
                                 (cast(ulong) ftime.dwLowDateTime);
        }
    }

    /**
     * Static method that simulates a constructor.
     *
     * Params:
     * usec     = interval of time in microseconds.
     */
    public static Interval opCall(ulong usec)
    {
        Interval interval;

        interval._usec = usec;

        return interval;
    }

    /**
     * Static method that simulates a constructor.
     *
     * Params:
     * sec      = interval of time in seconds.
     * usec     = interval of time in microseconds.
     *
     * Returns:
     * An Interval with the value: sec + usec * 1_000_000
     */
    public static Interval opCall(ulong sec, ulong usec)
    {
        Interval interval;

        interval.set(sec, usec);

        return interval;
    }

    /**
     * Static method that simulates a constructor.
     *
     * Params:
     * tv       = time duration with microsecond precision.
     *
     * Returns:
     * An Interval with the value: tv.tv_sec + tv.tv_usec * 1_000_000
     */
    public static Interval opCall(timeval tv)
    {
        Interval interval;

        interval.set(tv);

        return interval;
    }

    /**
     * Return the time interval in microseconds.
     */
    public ulong usec()
    {
        return _usec;
    }

    /**
     * Set the time interval in microseconds.
     */
    public void usec(ulong value)
    {
        _usec = value;
    }

    /**
     * Return the time interval in milliseconds.
     */
    public ulong msec()
    {
        return _usec / MsecToUsec;
    }

    /**
     * Set the time interval in milliseconds.
     */
    public void msec(ulong value)
    {
        _usec = value * MsecToUsec;
    }

    /**
     * Return the time interval in seconds.
     */
    public ulong sec()
    {
        return _usec / SecToUsec;
    }

    /**
     * Set the time interval in seconds.
     */
    public void sec(ulong value)
    {
        _usec = value * SecToUsec;
    }

    /**
     * Set the time interval in seconds.
     */
    public void set(ulong sec, ulong usec)
    {
        _usec = sec * SecToUsec + usec;
    }

    /**
     * Set the time interval from a C timeval struct.
     */
    public void set(timeval tv)
    {
        _usec = tv.tv_sec * SecToUsec + tv.tv_usec;
    }

    /**
     * Check if two intervals are equal.
     */
    public bool opEquals(Interval value)
    {
        return _usec == value._usec;
    }

    /**
     * Compare two intervals.
     */
    public int opCmp(Interval value)
    {
        return (_usec < value._usec ? -1 : (_usec > value._usec ? 1 : 0));
    }

    /**
     * Add two time intervals.
     */
    public Interval opAdd(Interval interval)
    {
        return Interval(_usec + interval._usec);
    }

    /**
     * Add two time intervals.
     */
    public Interval opAddAssign(Interval interval)
    {
        _usec += interval._usec;
        return *this;
    }

    /**
     * Subtract two time intervals.
     */
    public Interval opSub(Interval interval)
    {
        return Interval(_usec - interval._usec);
    }

    /**
     * Subtract two time intervals.
     */
    public Interval opSubAssign(Interval interval)
    {
        _usec -= interval._usec;
        return *this;
    }

    /**
     * Multiply a time interval by a factor.
     */
    public Interval opMul(uint number)
    {
        return Interval(_usec * number);
    }

    /**
     * Multiply a time interval by a factor.
     */
    public Interval opMulAssign(uint number)
    {
        _usec *= number;
        return *this;
    }

    /**
     * Divide a time interval by a number.
     */
    public Interval opDiv(uint number)
    {
        return Interval(_usec / number);
    }

    /**
     * Multiply a time interval by a factor.
     */
    public Interval opDivAssign(uint number)
    {
        _usec /= number;
        return *this;
    }

    /**
     * Sets the interval value to the number of microseconds since
     * Jan 1, 1970 at 00:00:00 (current system time).
     *
     * Remarks:
     * On platforms that do not provide the current system time with
     * microsecond precision, the value will only have a 1-second prevision.
     */
    public void now()
    {
        version (Posix)
        {
            timeval tv;

            gettimeofday(&tv, null);

            _usec = tv.tv_sec * SecToUsec + tv.tv_usec;
        }
        else version (Win32)
        {
            FILETIME ft;

            GetSystemTimeAsFileTime(&ft);

            _usec = ((((cast(ulong) ftime.dwHighDateTime) << 32 |
                       (cast(ulong) ftime.dwLowDateTime)) - FiletimeToUsecSkew) / 10);
        }
        else
        {
            // Low precision compatibility method
            _usec = cast(ulong) time(null) * SecToUsec;
        }
    }

    /**
     * Cast the time interval to a C timeval struct.
     */
    public timeval* toTimeval()
    {
        return toTimeval(new timeval);
    }

    /**
     * Cast the time interval to a C timeval struct.
     */
    public timeval* toTimeval(timeval* tv)
    in
    {
        assert(tv !is null);
    }
    body
    {
        tv.tv_sec = cast(typeof(tv.tv_sec)) (_usec / SecToUsec);
        tv.tv_usec = cast(typeof(tv.tv_usec)) (_usec % SecToUsec);

        return tv;
    }

    /**
     * Cast the time interval to a C time_t.
     */
    public time_t toTime_t()
    {
        return cast(time_t) (_usec / SecToUsec);
    }

    version (Posix)
    {
        /**
         * Cast the time interval to a C timespec struct.
         */
        public timespec* toTimespec()
        {
            return toTimespec(new timespec);
        }

        /**
         * Cast the time interval to a C timespec struct.
         */
        public timespec* toTimespec(timespec* ts)
        in
        {
            assert(ts !is null);
        }
        body
        {
            ts.tv_sec = cast(typeof(ts.tv_sec)) (_usec / SecToUsec);
            ts.tv_nsec = cast(typeof(ts.tv_nsec)) ((_usec % SecToUsec) * USecToNsec);

            return ts;
        }
    }

    unittest
    {
        timeval tv1;
        timeval *tv2;
        time_t  t;

        // Default constructor
        Interval i1;
        assert(i1.sec() == 0);
        assert(i1.msec() == 0);
        assert(i1.usec() == 0);
        // Interval.zero
        assert(i1 == Interval.zero);
        // Constructor from usecs
        Interval i2 = Interval(1_234_567);
        assert(i2.sec() == 1);
        assert(i2.msec() == 1_234);
        assert(i2.usec() == 1_234_567);
        // Constructor from secs, usecs
        Interval i3 = Interval(1, 234_567);
        assert(i3.sec() == 1);
        assert(i3.msec() == 1_234);
        assert(i3.usec() == 1_234_567);
        // Constructor from timeval
        tv1.tv_sec = 123;
        tv1.tv_usec = 789;
        Interval i4 = Interval(tv1);
        assert(i4.sec() == 123);
        assert(i4.msec() == 123_000);
        assert(i4.usec() == 123_000_789);

        // Pseudo-constructors using time units
        i1 = Usec(987);
        assert(i1.usec() == 987);
        i1 = Msec(876);
        assert(i1.msec() == 876);
        i1 = Sec(765);
        assert(i1.sec() == 765);
        i1 = Min(3);
        assert(i1.sec() == 3 * 60);
        i1 = Hour(2);
        assert(i1.sec() == 2 * 60 * 60);

        // Interval.sec(secs)
        i1.sec(3);
        assert(i1.sec() == 3);
        assert(i1.msec() == 3_000);
        assert(i1.usec() == 3_000_000);
        // Interval.msec(msecs)
        i1.msec(4_567);
        assert(i1.sec() == 4);
        assert(i1.msec() == 4_567);
        assert(i1.usec() == 4_567_000);
        // Interval.usec(usecs)
        i1.usec(12_345_678);
        assert(i1.sec() == 12);
        assert(i1.msec() == 12_345);
        assert(i1.usec() == 12_345_678);
        // Interval.set(sec,usecs)
        i1.set(34, 567_890);
        assert(i1.sec() == 34);
        assert(i1.msec() == 34_567);
        assert(i1.usec() == 34_567_890);
        // Interval.set(timeval)
        tv1.tv_sec = 0;
        tv1.tv_usec = 1;
        i1.set(tv1);
        assert(i1.sec() == 0);
        assert(i1.msec() == 0);
        assert(i1.usec() == 1);
        // Interval.opAdd()
        i2.usec(111_111_111);
        i3.usec(333_333_333);
        i1 = i2 + i3;
        assert(i1.usec() == 444_444_444);
        // Interval.opAddAssign()
        i1 += i2;
        assert(i1.usec() == 555_555_555);
        // Interval.opSub()
        i1 = i3 - i2;
        assert(i1.usec() == 222_222_222);
        // Interval.opSubAssign()
        i1 -= i2;
        assert(i1.usec() == 111_111_111);
        // Interval.opMul()
        i1 = i2 * 2;
        assert(i1.usec() == 222_222_222);
        // Interval.opMulAssign()
        i1 *= 3;
        assert(i1.usec() == 666_666_666);
        // Interval.opDiv()
        i1 = i3 / 2;
        assert(i1.usec() == 166_666_666);
        // Interval.opDivAssign()
        i1.usec(111_111_111);
        i1 /= 11;
        assert(i1.usec() == 10_101_010);
        // Interval.toTimeval()
        tv2 = i1.toTimeval();
        assert(tv2.tv_sec == 10 && tv2.tv_usec == 101_010);
        // Interval.toTime_t()
        t = i1.toTime_t();
        assert(t == 10);
    }
}


/** Pseudo-constructor for time intervals specified in microseconds */
Interval Usec(ulong value)
{
    return Interval(value);
}
alias Usec Microsecond;

/** Pseudo-constructor for time intervals specified in milliseconds */
Interval Msec(ulong value)
{
    return Interval(value * MsecToUsec);
}
alias Msec Millisecond;

/** Pseudo-constructor for time intervals specified in seconds */
Interval Sec(ulong value)
{
    return Interval(value * SecToUsec);
}
alias Sec Second;

/** Pseudo-constructor for time intervals specified in minutes */
Interval Min(ulong value)
{
    return Interval(value * SecToUsec * 60);
}
alias Min Minute;

/** Pseudo-constructor for time intervals specified in hours */
Interval Hour(ulong value)
{
    return Interval(value * SecToUsec * 60 * 60);
}
