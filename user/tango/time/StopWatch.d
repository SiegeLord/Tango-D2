/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Feb 2007: Initial release
        
        author:         Kris

*******************************************************************************/

module tango.time.StopWatch;
import tango.core.PerformanceTimers;

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
