/*******************************************************************************

        Shows how the basic functionality of Logger operates.

*******************************************************************************/

private import tango.util.log.Log,
               tango.util.log.Configurator;

private import tango.text.convert.Sprint;

/*******************************************************************************

*******************************************************************************/

private class Sieve
{
        private Logger logger;
        
        /***********************************************************************

                Initialize the Sieve class 

        ***********************************************************************/

        this()
        {
                // get a logger for this object. Could make this static instead
                logger = Log.getLogger ("example.logging.Sieve");
        }

        /***********************************************************************

                Search for a set of prime numbers

        ***********************************************************************/

        void compute (uint max)
        {
                byte*   feld;
                int     teste=1,
                        mom,
                        hits=0,
                        s=0,
                        e = 1;
                int     count;
                auto    sprint = new Sprint!(char);

                void set (byte* f, uint x)
                {
                        *(f+(x)/16) |= 1 << (((x)%16)/2);
                }

                byte test (byte* f, uint x)
                {
                        return cast(byte) (*(f+(x)/16) & (1 << (((x)%16)/2)));
                }

                // information level
                logger.info (sprint ("Searching prime numbers to : {0}", max));

                feld = (new byte[max / 16 + 1]).ptr;

                // get milliseconds since application began
                ulong begin = logger.getRuntime();

                while ((teste += 2) < max)
                        if (! test (feld, teste)) 
                           {
                           if  ((++hits & 0x0f) == 0) 
                                // more information level
                                logger.info (sprint ("found {0}", hits)); 

                           for (mom=3*teste; mom < max; mom += teste<<1) 
                                set (feld, mom);
                           }

                // get number of milliseconds we took to compute
                ulong period = logger.getRuntime() - begin;

                if (hits)
                    // more information
                    logger.info (sprint ("{0} prime numbers found in {1} millsecs", hits, period));
                else
                   // a warning level
                   logger.warn ("no prime numbers found");
        
                // check to see if we're enabled for 
                // tracing before we expend a lot of effort
                if (logger.isEnabled (logger.Level.Trace))
                   {        
                   e = max;
                   count = 0 - 2; 
                   if (s % 2 is 0) 
                       count++;
           
                   while ((count+=2) < e) 
                           // log trace information
                           if (! test (feld, count)) 
                               logger.trace (sprint ("prime found: {0}", count));
                   }
        }
}


/*******************************************************************************

        Create a Sieve and have it compute a bunch of prime numbers.

*******************************************************************************/

void main()
{
        // get a logger to represent this module. We could just as
        // easily share a name with some other module(s)
        auto logger = Log.getLogger ("example.logging");
        
        // set up a basic logging configuration
        Configurator ();

        try {
            Sieve sieve = new Sieve;

            sieve.compute (1000);

            } catch (Exception x)
                    {
                    // log the exception as an error
                    logger.error ("Exception: " ~ x.toUtf8);
                    }
}
