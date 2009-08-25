/// basic high resolution timing functions:
/// clock_gettime and its argument: timespec, time_t, clockid_t
///
/// author: fawzi
/// license: tango, apache 2.0
module tango.stdc.posix.timer;
import tango.stdc.config;

extern(C):

alias c_long time_t;

//
// Timer (TMR)
//
/*
struct timespec
{
    time_t  tv_sec;
    int     tv_nsec;
}
*/

version( linux )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version( darwin )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version( freebsd )
{
    struct timespec
    {
        time_t  tv_sec;
        c_long  tv_nsec;
    }
}
else version ( solaris )
{
    struct timespec         /* definition per POSIX.4 */
    {
        time_t  tv_sec;     /* seconds */
        c_long  tv_nsec;    /* and nanoseconds */
    }
}

version( linux )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 2; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 3; // (TMR|TCT)
    const CLOCK_REALTIME    = 0;
    const TIMER_ABSTIME     = 0x01;

    alias int clockid_t;

//    extern int clock_gettime(clockid_t, timespec*);
//    pragma(lib,"rt");

}
else version( darwin )
{
    // clock_gettime is not available
}
else version( freebsd )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 2; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 3; // (TMR|TCT)
    const CLOCK_REALTIME    = 0;
    const TIMER_ABSTIME     = 0x01;

    alias int clockid_t;

    extern int clock_gettime(clockid_t, timespec*);
}
else version( solaris )
{
    const CLOCK_PROCESS_CPUTIME_ID  = 5; // (TMR|CPT)
    const CLOCK_THREAD_CPUTIME_ID   = 2; // (TMR|TCT)
    const CLOCK_REALTIME    = 3;
    const TIMER_ABSTIME     = 0x1;

    alias int clockid_t;

    extern int clock_gettime(clockid_t, timespec*);
}

