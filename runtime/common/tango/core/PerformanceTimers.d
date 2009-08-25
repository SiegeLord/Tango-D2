/*******************************************************************************
    performance timers
    
    mind that frequncy is not the resolution of the timer:
    the actual timer resolution might be larger (i.e. have smaller frequency)
    than the frequency returned
    
        license:        tango, apache 2.0
        author:         fawzi

*******************************************************************************/

module tango.core.PerformanceTimers;
private import tango.core.Exception;

version (Win32)
{
    private extern (Windows) 
    {
        int QueryPerformanceCounter   (ulong *count);
        int QueryPerformanceFrequency (ulong *frequency);
    }
}

version (Posix)
{
    private import tango.stdc.posix.sys.time;
    private import tango.stdc.posix.timer;
}

version (Win32){
    /// systemwide realtime clock
    ulong realtimeClock(){
        ulong res;
        if (! QueryPerformanceCounter (&res))
            throw new PlatformException ("high-resolution timer is not available");
        return res;
    }
    /// frequency (in seconds) of the systemwide realtime clock
    ulong realtimeClockFreq(){
        ulong res;
        if (! QueryPerformanceFrequency (&res))
            throw new PlatformException ("high-resolution timer is not available");
        return res;
    }
    /// realtime clock, need to be valid only on one cpu
    /// if the thread migrates from a cpu to another ther result might be bogus
    ulong cpuClock(){
        ulong res;
        if (! QueryPerformanceCounter (&res))
            throw new PlatformException ("high-resolution timer is not available");
        return res;
    }
    /// frequency (in seconds) of the cpu realtime clock
    ulong cpuClockFreq(){
        ulong res;
        if (! QueryPerformanceFrequency (&res))
            throw new PlatformException ("high-resolution timer is not available");
        return res;
    }
    
} else version (Posix) {
    
    // realtime (global) clock
    static if (is(typeof(timespec)) && is(typeof(clock_gettime(CLOCK_REALTIME,cast(timespec*)null)))){
        /// systemwide realtime clock
        ulong realtimeClock(){
            timespec ts;
            clock_gettime(CLOCK_REALTIME,&ts);
            return cast(ulong)ts.tv_nsec+1_000_000_000UL*cast(ulong)ts.tv_sec;
        }
        /// frequency (in seconds) of the systemwide realtime clock
        ulong realtimeClockFreq(){
            return 1_000_000_000UL;
        }
    } else {
        /// systemwide realtime clock
        ulong realtimeClock(){
            timeval tv;
            if (gettimeofday (&tv, null))
                throw new PlatformException ("Timer :: linux timer is not available");

            return (cast(ulong) tv.tv_sec * 1_000_000) + tv.tv_usec;
        }
        
        /// frequency (in seconds) of the systemwide realtime clock
        ulong realtimeClockFreq(){
            return 1_000_000UL;
        }
    }
    
    // cpu clock
    
    static if (is(typeof(timespec)) &&
        is(typeof(clock_gettime(CLOCK_THREAD_CPUTIME_ID,cast(timespec*)null)))){
        /// realtime clock, need to be valid only on one cpu
        /// if the thread migrates from a cpu to another ther result might be bogus
        ulong cpuClock(){
            timespec ts;
            clock_gettime(CLOCK_REALTIME,&ts);
            return cast(ulong)ts.tv_nsec+1_000_000_000UL*cast(ulong)ts.tv_sec;
        }
        /// frequency (in seconds) of the systemwide realtime clock
        ulong cpuClockFreq(){
            return 1_000_000_000UL;
        }
    } else static if (is(typeof(timespec)) && 
        is(typeof(clock_gettime(CLOCK_REALTIME,cast(timespec*)null))))
    {
        /// realtime clock, need to be valid only on one cpu
        /// if the thread migrates from a cpu to another ther result might be bogus
        ulong cpuClock(){
            timespec ts;
            clock_gettime(CLOCK_REALTIME,&ts);
            return cast(ulong)ts.tv_nsec+1_000_000_000UL*cast(ulong)ts.tv_sec;
        }
        /// frequency (in seconds) of the systemwide realtime clock
        ulong cpuClockFreq(){
            return 1_000_000_000UL;
        }
    } else {
        /// realtime clock, need to be valid only on one cpu
        /// if the thread migrates from a cpu to another ther result might be bogus
        ulong cpuClock(){
            timeval tv;
            if (gettimeofday (&tv, null))
                throw new PlatformException ("Timer :: linux timer is not available");

            return (cast(ulong) tv.tv_sec * 1_000_000) + tv.tv_usec;
        }
        
        /// frequency (in seconds) of the systemwide realtime clock
        ulong cpuClockFreq(){
            return 1_000_000UL;
        }
    }
}
