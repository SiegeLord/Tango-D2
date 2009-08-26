/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Feb 2007: Initial release
        
        author:         Kris

*******************************************************************************/

module tango.time.StopWatch;
import tango.core.Exception;

version (Win32){
    private extern (Windows) 
    {
        int QueryPerformanceCounter   (ulong *count);
        int QueryPerformanceFrequency (ulong *frequency);
    }
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
    private import tango.stdc.posix.sys.time;
    private import tango.stdc.posix.timer;
    
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

/*******************************************************************************

        Timer for measuring small intervals, such as the duration of a 
        subroutine or other reasonably small period.
        ---
        StopWatch elapsed;

        elapsed.start;

        // do something
        // ...

        double i = elapsed.stop;
        ---

        The measured interval is in units of seconds, using floating-
        point to represent fractions. This approach is more flexible 
        than integer arithmetic since it migrates trivially to more
        capable timer hardware (there no implicit granularity to the
        measurable intervals, except the limits of fp representation)

        StopWatch is accurate to the extent of what the underlying OS
        supports. On linux systems, this accuracy is typically 1 us at 
        best. Win32 is generally more precise. 

        There is some minor overhead in using StopWatch, so take that into 
        account

*******************************************************************************/

public struct StopWatch
{
        private ulong  started;
        private static double multiplier;
        private static double microsecond;
        static this(){
            multiplier=1.0/cast(real)realtimeClockFreq();
            microsecond=1.0E6/cast(real)realtimeClockFreq();
        }

        /***********************************************************************
                
                Start the timer

        ***********************************************************************/
        
        void start ()
        {
            started = realtimeClock();
        }

        /***********************************************************************
                
                Stop the timer and return elapsed duration since start()

        ***********************************************************************/
        
        double stop ()
        {
            return multiplier * (realtimeClock() - started);
        }

        /***********************************************************************
                
                Return elapsed time since the last start() as microseconds

        ***********************************************************************/
        
        ulong microsec ()
        {
            return cast(ulong) ((realtimeClock() - started) * microsecond);
        }

        /***********************************************************************
                
                Return the current time as an Interval

        ***********************************************************************/

        private static ulong timer ()
        {
            return realtimeClock();
        }
}


/*******************************************************************************

*******************************************************************************/

debug (StopWatch)
{
        import tango.io.Stdout;

        void main() 
        {
                StopWatch t;
                t.start;

                for (int i=0; i < 100_000_000; ++i)
                    {}
                Stdout.format ("{:f9}", t.stop).newline;
        }
}
