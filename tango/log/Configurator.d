/*******************************************************************************

        @file Configurator.d

        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      
        @version        Initial version, May 2004
        @author         Kris


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
