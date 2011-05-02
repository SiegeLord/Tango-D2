/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.time;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types;  // for time_t, suseconds_t
public import tango.stdc.posix.sys.select; // for fd_set, FD_CLR() FD_ISSET() FD_SET() FD_ZERO() FD_SETSIZE

extern (C):

//
// XOpen (XSI)
//
/*
struct timeval
{
    time_t      tv_sec;
    suseconds_t tv_usec;
}

struct itimerval
{
    timeval it_interval;
    timeval it_value;
}

ITIMER_REAL
ITIMER_VIRTUAL
ITIMER_PROF

int getitimer(int, itimerval*);
int gettimeofday(timeval*, void*);
int select(int, fd_set*, fd_set*, fd_set*, timeval*);
int setitimer(int, in itimerval*, itimerval*);
int utimes(in char*, in timeval[2]); // LEGACY
*/

version( linux )
{
    struct timeval
    {
        time_t      tv_sec;
        suseconds_t tv_usec;
    }

    struct itimerval
    {
        timeval it_interval;
        timeval it_value;
    }

    const ITIMER_REAL       = 0;
    const ITIMER_VIRTUAL    = 1;
    const ITIMER_PROF       = 2;

    int getitimer(int, itimerval*);
    int gettimeofday(timeval*, void*);
    int select(int, fd_set*, fd_set*, fd_set*, timeval*);
    int setitimer(int, in itimerval*, itimerval*);
    int utimes(in char*, in timeval[2]); // LEGACY
}
else version( darwin )
{
    struct timeval
    {
        time_t      tv_sec;
        suseconds_t tv_usec;
    }

    struct itimerval
    {
        timeval it_interval;
        timeval it_value;
    }

    // non-standard
    struct timezone_t
    {
        int tz_minuteswest;
        int tz_dsttime;
    }

    int getitimer(int, itimerval*);
    int gettimeofday(timeval*, timezone_t*); // timezone_t* is normally void*
    int select(int, fd_set*, fd_set*, fd_set*, timeval*);
    int setitimer(int, in itimerval*, itimerval*);
    int utimes(in char*, in timeval[2]);
}
else version( freebsd )
{
    struct timeval
    {
        time_t      tv_sec;
        suseconds_t tv_usec;
    }

    struct itimerval
    {
        timeval it_interval;
        timeval it_value;
    }

    // non-standard
    struct timezone_t
    {
        int tz_minuteswest;
        int tz_dsttime;
    }

    int getitimer(int, itimerval*);
    int gettimeofday(timeval*, timezone_t*); // timezone_t* is normally void*
    int select(int, fd_set*, fd_set*, fd_set*, timeval*);
    int setitimer(int, in itimerval*, itimerval*);
    int utimes(in char*, in timeval[2]);
}
else version( solaris )
{
    struct timeval
    {
        time_t      tv_sec;
        suseconds_t tv_usec;
    }

    struct itimerval
    {
        timeval it_interval;
        timeval it_value;
    }

    // non-standard
    struct timezone_t
    {
        int tz_minuteswest;
        int tz_dsttime;
    }

    int getitimer(int, itimerval*);
    int gettimeofday(timeval*, timezone_t*); // timezone_t* is normally void*
    int select(int, fd_set*, fd_set*, fd_set*, timeval*);
    int setitimer(int, in itimerval*, itimerval*);
    int utimes(in char*, in timeval*);
}
