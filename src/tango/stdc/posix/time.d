/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.time;

private import tango.stdc.posix.config;
public import tango.stdc.time;
public import tango.stdc.posix.sys.types;
public import tango.stdc.posix.signal; // for sigevent

extern (C):

//
// Required (defined in tango.stdc.time)
//
/*
char* asctime(in tm*);
clock_t clock();
char* ctime(in time_t*);
double difftime(time_t, time_t);
tm* gmtime(in time_t*);
tm* localtime(in time_t*);
time_t mktime(tm*);
size_t strftime(char*, size_t, in char*, in tm*);
time_t time(time_t*);
*/

version( linux )
{
    time_t timegm(tm*); // non-standard
}
else version( darwin )
{
    time_t timegm(tm*); // non-standard
}
else version( freebsd )
{
    time_t timegm(tm*); // non-standard
}
else version( solaris )
{
    time_t timegm(tm* t) // non-standard
    {
        time_t tl, tb;
        tm *tg;

        tl = mktime (t);
        if (tl == -1)
        {
            t.tm_hour--;
            tl = mktime (t);
            if (tl == -1)
                return -1; /* can't deal with output from strptime */
            tl += 3600;
        }
        tg = gmtime (&tl);
        tg.tm_isdst = 0;
        tb = mktime (tg);
        if (tb == -1)
        {
            tg.tm_hour--;
            tb = mktime (tg);
            if (tb == -1)
                return -1; /* can't deal with output from gmtime */
            tb += 3600;
        }
        return (tl - (tb - tl));
    }
}

//
// C Extension (CX)
// (defined in tango.stdc.time)
//
/*
char* tzname[];
void tzset();
*/

//
// Process CPU-Time Clocks (CPT)
//
/*
int clock_getcpuclockid(pid_t, clockid_t*);
*/

//
// Clock Selection (CS)
//
/*
int clock_nanosleep(clockid_t, int, in timespec*, timespec*);
*/

//
// Monotonic Clock (MON)
//
/*
CLOCK_MONOTONIC
*/

//
// Timer (TMR)
//
/*
CLOCK_PROCESS_CPUTIME_ID (TMR|CPT)
CLOCK_THREAD_CPUTIME_ID (TMR|TCT)

NOTE: timespec must be defined in tango.stdc.posix.signal to break
      a circular import.

struct timespec
{
    time_t  tv_sec;
    int     tv_nsec;
}

struct itimerspec
{
    timespec it_interval;
    timespec it_value;
}

CLOCK_REALTIME
TIMER_ABSTIME

clockid_t
timer_t

int clock_getres(clockid_t, timespec*);
int clock_gettime(clockid_t, timespec*);
int clock_settime(clockid_t, in timespec*);
int nanosleep(in timespec*, timespec*);
int timer_create(clockid_t, sigevent*, timer_t*);
int timer_delete(timer_t);
int timer_gettime(timer_t, itimerspec*);
int timer_getoverrun(timer_t);
int timer_settime(timer_t, int, in itimerspec*, itimerspec*);
*/

version( linux )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 2; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 3; // (TMR|TCT)

    // NOTE: See above for why this is commented out.
    //
    //struct timespec
    //{
    //    time_t  tv_sec;
    //    c_long  tv_nsec;
    //}

    struct itimerspec
    {
        timespec it_interval;
        timespec it_value;
    }

    const CLOCK_REALTIME    = 0;
    const TIMER_ABSTIME     = 0x01;

    alias int clockid_t;
    alias int timer_t;

    int clock_getres(clockid_t, timespec*);
    //int clock_gettime(clockid_t, timespec*);
    //int clock_settime(clockid_t, in timespec*);
    int nanosleep(in timespec*, timespec*);
    int timer_create(clockid_t, sigevent*, timer_t*);
    int timer_delete(timer_t);
    int timer_gettime(timer_t, itimerspec*);
    int timer_getoverrun(timer_t);
    int timer_settime(timer_t, int, in itimerspec*, itimerspec*);
}
else version( darwin )
{
    int nanosleep(in timespec*, timespec*);
}
else version( freebsd )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 2; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 3; // (TMR|TCT)

    // NOTE: See above for why this is commented out.
    //
    //struct timespec
    //{
    //    time_t  tv_sec;
    //    c_long  tv_nsec;
    //}

    struct itimerspec
    {
        timespec it_interval;
        timespec it_value;
    }

    const CLOCK_REALTIME    = 0;
    const TIMER_ABSTIME     = 0x01;

    alias int clockid_t;
    alias int timer_t;

    int clock_getres(clockid_t, timespec*);
    int clock_gettime(clockid_t, timespec*);
    int clock_settime(clockid_t, in timespec*);
    int nanosleep(in timespec*, timespec*);
    int timer_create(clockid_t, sigevent*, timer_t*);
    int timer_delete(timer_t);
    int timer_gettime(timer_t, itimerspec*);
    int timer_getoverrun(timer_t);
    int timer_settime(timer_t, int, in itimerspec*, itimerspec*);
}
else version( solaris )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 5; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 2; // (TMR|TCT)

    // NOTE: See above for why this is commented out.
    //
    //struct timespec
    //{
    //    time_t  tv_sec;
    //    c_long  tv_nsec;
    //}

    struct itimerspec
    {
        timespec it_interval;
        timespec it_value;
    }
	
    const CLOCK_REALTIME    = 3;
    const TIMER_ABSTIME     = 0x1;

    alias int clockid_t;
    alias int timer_t;

    int clock_getres(clockid_t, timespec*);
    int clock_gettime(clockid_t, timespec*);
    int clock_settime(clockid_t, in timespec*);
    int nanosleep(in timespec*, timespec*);
    int timer_create(clockid_t, sigevent*, timer_t*);
    int timer_delete(timer_t);
    int timer_gettime(timer_t, itimerspec*);
    int timer_getoverrun(timer_t);
    int timer_settime(timer_t, int, in itimerspec*, itimerspec*);
}


//
// Thread-Safe Functions (TSF)
//
/*
char* asctime_r(in tm*, char*);
char* ctime_r(in time_t*, char*);
tm*   gmtime_r(in time_t*, tm*);
tm*   localtime_r(in time_t*, tm*);
*/

version( linux )
{
    char* asctime_r(in tm*, char*);
    char* ctime_r(in time_t*, char*);
    tm*   gmtime_r(in time_t*, tm*);
    tm*   localtime_r(in time_t*, tm*);
}
else version( darwin )
{
    char* asctime_r(in tm*, char*);
    char* ctime_r(in time_t*, char*);
    tm*   gmtime_r(in time_t*, tm*);
    tm*   localtime_r(in time_t*, tm*);
}
else version( freebsd )
{
    char* asctime_r(in tm*, char*);
    char* ctime_r(in time_t*, char*);
    tm*   gmtime_r(in time_t*, tm*);
    tm*   localtime_r(in time_t*, tm*);
}
else version( solaris )
{
    char* asctime_r(in tm*, char*);
    char* ctime_r(in time_t*, char*);
    tm*   gmtime_r(in time_t*, tm*);
    tm*   localtime_r(in time_t*, tm*);
}

//
// XOpen (XSI)
//
/*
getdate_err

int daylight;
int timezone;

tm* getdate(in char*);
char* strptime(in char*, in char*, tm*);
*/

version( linux )
{
    extern int      daylight;
    extern c_long   timezone;

    tm*   getdate(in char*);
    char* strptime(in char*, in char*, tm*);
}
else version( darwin )
{
    extern c_long timezone;

    tm*   getdate(in char*);
    char* strptime(in char*, in char*, tm*);
}
else version( freebsd )
{
    extern c_long timezone;

    //tm*   getdate(in char*);
    char* strptime(in char*, in char*, tm*);
}
else version( solaris )
{
    extern c_long timezone;

    tm*   getdate(in char*);
    char* strptime(in char*, in char*, tm*);
}
