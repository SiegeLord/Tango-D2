/*******************************************************************************

        Shows how the basic functionality of Logger operates.

*******************************************************************************/

import tango.util.log.Log,
       Config = tango.util.log.Config;

/*******************************************************************************

        Search for a set of prime numbers

*******************************************************************************/

void compute (Logger log, uint max)
{
                byte*   feld;
                int     teste=1,
                        mom,
                        hits=0,
                        s=0,
                        e = 1;
                int     count;

                void set (byte* f, uint x)
                {
                        *(f+(x)/16) |= 1 << (((x)%16)/2);
                }

                byte test (byte* f, uint x)
                {
                        return cast(byte) (*(f+(x)/16) & (1 << (((x)%16)/2)));
                }

                // information level
                log.info ("Searching prime numbers up to {}", max);

                feld = (new byte[max / 16 + 1]).ptr;

                while ((teste += 2) < max)
                        if (! test (feld, teste)) 
                           {
                           if  ((++hits & 0x0f) == 0) 
                                // more information level
                                log.info ("found {}", hits); 

                           for (mom=3*teste; mom < max; mom += teste<<1) 
                                set (feld, mom);
                           }

                if (hits)
                    // more information
                    log.info ("{} prime numbers found", hits);
                else
                   // a warning level
                   log.warn ("no prime numbers found");
        
                // check to see if we're enabled for 
                // tracing before we expend a lot of effort
                if (log.enabled (Level.Trace))
                   {        
                   e = max;
                   count = 0 - 2; 
                   if (s % 2 is 0) 
                       count++;
           
                   while ((count+=2) < e) 
                           // log trace information
                           if (! test (feld, count)) 
                                 log.trace ("prime found: {}", count);
                   }
}


/*******************************************************************************

        Compute a bunch of prime numbers

*******************************************************************************/

void main()
{
        // get a logger to represent this module
        auto log = Config.Log.lookup ("example.logging");
        try {
            compute (log, 1000);
            } catch (Exception x)
                    {
                    // log the exception as a fatal error
                    log.fatal ("Exception: " ~ x.toString());
                    }
}
