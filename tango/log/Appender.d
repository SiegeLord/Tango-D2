/*******************************************************************************

        @file Appender.d

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

module tango.log.Appender;

public import   tango.log.Event,
                tango.log.Layout;

/*******************************************************************************

        Base class for all Appenders. These objects are responsible for
        emitting messages sent to a particular logger. There may be more
        than one appender attached to any logger. The actual message is
        constructed by another class known as a Layout.
        
*******************************************************************************/

public class Appender
{
        private Appender        next;
        private Layout          layout;

        /***********************************************************************
                
                Return the mask used to identify this Appender. The mask
                is used to figure out whether an appender has already been 
                invoked for a particular logger.

        ***********************************************************************/

        abstract uint getMask ();

        /***********************************************************************
                
                Return the name of this Appender.

        ***********************************************************************/

        abstract char[] getName ();
                
        /***********************************************************************
                
                Append a message to the output.

        ***********************************************************************/

        abstract void append (Event event);

        /***********************************************************************
              
              Create an Appender and default its layout to SimpleLayout.  

        ***********************************************************************/

        this ()
        {
                layout = new SimpleLayout;
        }

        /***********************************************************************
                
                Static method to return a mask for identifying the Appender.
                Each Appender class should have a unique fingerprint so that
                we can figure out which ones have been invoked for a given
                event. A bitmask is a simple an efficient way to do that.

        ***********************************************************************/

        protected static uint nextMask()
        {
                static uint mask = 1;

                uint ret = mask;
                mask <<= 1;
                return ret;
        }

        /***********************************************************************
                
                Set the current layout to be that of the argument.

        ***********************************************************************/

        void setLayout (Layout layout)
        {
                this.layout = layout;
        }

        /***********************************************************************
                
                Return the current Layout

        ***********************************************************************/

        Layout getLayout ()
        {
                return layout;
        }

        /***********************************************************************
                
                Attach another appender to this one

        ***********************************************************************/

        void setNext (Appender next)
        {
                this.next = next;
        }

        /***********************************************************************
                
                Return the next appender in the list

        ***********************************************************************/

        Appender getNext ()
        {
                return next;
        }

        /***********************************************************************
                
                Close this appender. This would be used for file, sockets, 
                and such like.

        ***********************************************************************/

        void close ()
        {
        }
}

