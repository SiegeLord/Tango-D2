/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

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
        private Mask mask;

        /***********************************************************************
                
                Create with the given Layout

        ***********************************************************************/

        this (Layout layout = null)
        {
                // Get a unique fingerprint for this class
                mask = register (getName);

                setLayout (layout);
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        Mask getMask ()
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
                             Cerr.newline;
                             }
                }
        }
}
