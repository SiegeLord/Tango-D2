/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.Configurator;

private import  tango.log.Logger,
                tango.log.Layout,
                tango.log.DateLayout,
                tango.log.ConsoleAppender;

/*******************************************************************************

        A utility class for initializing the basic behaviour of the
        default logging hierarchy.

*******************************************************************************/

public class BasicConfigurator
{
        /***********************************************************************

                Create a default StdioAppender with a SimpleTimerLayout.

        ***********************************************************************/

        static protected Logger defaultAppender ()
        {
                // get the hierarchy root
                Logger root = Logger.getRootLogger();

                // setup a default appender
                root.addAppender (new ConsoleAppender (new SimpleTimerLayout));

                return root;
        }

        /***********************************************************************

                Add a default StdioAppender, with a SimpleTimerLayout, to 
                the root node, and set the default activity level to be
                everything enabled.
                
        ***********************************************************************/

        static void configure ()
        {
                // enable all messages for all loggers
                defaultAppender().setLevel (Logger.Level.Trace);
        }
}
