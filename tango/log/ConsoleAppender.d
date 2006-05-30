/*******************************************************************************

        @file ConsoleAppender.d

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

module tango.log.ConsoleAppender;

private import tango.log.Appender;

version (Isolated)
         private import std.stream;
      else
         private import tango.io.Console;

/*******************************************************************************

        Append to the console. This will use either streams or tango.io
        depending upon configuration

*******************************************************************************/

public class ConsoleAppender : Appender
{
        private static uint mask;

        /***********************************************************************
                
                Get a unique fingerprint for this class

        ***********************************************************************/

        static this()
        {
                mask = nextMask();
        }

        /***********************************************************************
               
                Create a basic ConsoleAppender

        ***********************************************************************/

        this ()
        {
        }

        /***********************************************************************
                
                Create with the given Layout

        ***********************************************************************/

        this (Layout layout)
        {
                setLayout (layout);
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        uint getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
               
                Append an event to the output.
                 
        ***********************************************************************/

        void append (Event event)
        {
                version (Isolated)
                {
                synchronized (stderr)
                             {
                             Layout layout = getLayout;
                             stderr.writeString (layout.header  (event));
                             stderr.writeString (layout.content (event));
                             stderr.writeString (layout.footer  (event));
                             stderr.writeLine (null);
                             }
                }
                else
                {
                synchronized (this)
                             {
                             Layout layout = getLayout;
                             Cerr.append (layout.header  (event));
                             Cerr.append (layout.content (event));
                             Cerr.append (layout.footer  (event));                        
                             Cerr ("\n");
                             }
                }
        }
}
