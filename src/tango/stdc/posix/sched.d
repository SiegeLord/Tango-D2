/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sched;

private import tango.stdc.posix.config;
public import tango.stdc.posix.time;
public import tango.stdc.posix.sys.types;

extern (C):

//
// Required
//
/*
struct sched_param
{
    int sched_priority (THR)
    int sched_ss_low_priority (SS|TSP)
    struct timespec sched_ss_repl_period (SS|TSP)
    struct timespec sched_ss_init_budget (SS|TSP)
    int sched_ss_max_repl (SS|TSP)
}

SCHED_FIFO
SCHED_RR
SCHED_SPORADIC (SS|TSP)
SCHED_OTHER

int sched_getparam(pid_t, sched_param*);
int sched_getscheduler(pid_t);
int sched_setparam(pid_t, in sched_param*);
int sched_setscheduler(pid_t, int, in sched_param*);
*/

version( linux )
{
    struct sched_param
    {
        int sched_priority;
    }

    const SCHED_OTHER   = 0;
    const SCHED_FIFO    = 1;
    const SCHED_RR      = 2;
    //SCHED_SPORADIC (SS|TSP)
}
else version( darwin )
{
    const SCHED_OTHER   = 1;
    const SCHED_FIFO    = 4;
    const SCHED_RR      = 2;
    // SCHED_SPORADIC seems to be unavailable

    private const __SCHED_PARAM_SIZE__ = 4;

    struct sched_param
    {
        int                         sched_priority;
        byte[__SCHED_PARAM_SIZE__]  opaque;
    }
}
else version( freebsd )
{
    struct sched_param
    {
        int sched_priority;
    }

	const SCHED_FIFO    = 1;
    const SCHED_OTHER   = 2;
    const SCHED_RR      = 3;
    //SCHED_SPORADIC (SS|TSP)
}
else version( solaris )
{
	struct sched_param
	{
		int		sched_priority;
		int[8]	sched_pad;
	}

	const SCHED_FIFO    = 1;
    const SCHED_OTHER   = 0;
    const SCHED_RR      = 2;
    //SCHED_SPORADIC ?
}

int sched_getparam(pid_t, sched_param*);
int sched_getscheduler(pid_t);
int sched_setparam(pid_t, in sched_param*);
int sched_setscheduler(pid_t, int, in sched_param*);

//
// Thread (THR)
//
/*
int sched_yield();
*/

version( linux )
{
    int sched_yield();
}
else version( darwin )
{
    int sched_yield();
}
else version( freebsd )
{
	int sched_yield();
}
else version( solaris )
{
	int sched_yield();
}

//
// Scheduling (TPS)
//
/*
int sched_get_priority_max(int);
int sched_get_priority_min(int);
int sched_rr_get_interval(pid_t, timespec*);
*/

version( linux )
{
    int sched_get_priority_max(int);
    int sched_get_priority_min(int);
    int sched_rr_get_interval(pid_t, timespec*);
}
else version( darwin )
{
    int sched_get_priority_min(int);
    int sched_get_priority_max(int);
    //int sched_rr_get_interval(pid_t, timespec*); // FIXME: unavailable?
}
else version( freebsd )
{
    int sched_get_priority_min(int);
    int sched_get_priority_max(int);
    int sched_rr_get_interval(pid_t, timespec*);
}
else version( solaris )
{
    int sched_get_priority_min(int);
    int sched_get_priority_max(int);
    int sched_rr_get_interval(pid_t, timespec*);
}