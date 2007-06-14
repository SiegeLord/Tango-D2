/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.EventLayout;

private import tango.util.log.Event;

private import tango.core.Type : Time;

/*******************************************************************************

        Base class for all logging layout instances

*******************************************************************************/

public class EventLayout
{
        /***********************************************************************
                
                Subclasses should implement this method to perform the
                formatting of each message header

        ***********************************************************************/

        abstract char[]  header (Event event);

        /***********************************************************************
                
                Subclasses should implement this method to perform the
                formatting of each message footer

        ***********************************************************************/

        char[] footer (Event event)
        {
                return "";
        }

        /***********************************************************************
                
                Subclasses should implement this method to perform the
                formatting of the actual message content.

        ***********************************************************************/

        char[] content (Event event)
        {
                return event.toUtf8;
        }

        /***********************************************************************
                
                Convert a time value (in milliseconds) to ascii

        ***********************************************************************/

        final char[] toMilli (char[] s, Time time)
        {
                assert (s.length > 0);
                time /= time.TicksPerMillisecond;

                int len = s.length;
                do {
                   s[--len] = time % 10 + '0';
                   time /= 10;
                   } while (time && len);
                return s[len..s.length];                
        }
}


/*******************************************************************************

        A bare layout comprised of tag and message

*******************************************************************************/

public class SpartanLayout : EventLayout
{
        /***********************************************************************
                
                Format outgoing message

        ***********************************************************************/

        char[] header (Event event)
        {
                event.append(event.getName).append(" - ");
                return event.getContent;
        }
}


/*******************************************************************************

        A simple layout comprised only of level, name, and message

*******************************************************************************/

public class SimpleLayout : EventLayout
{
        /***********************************************************************
                
                Format outgoing message

        ***********************************************************************/

        char[] header (Event event)
        {
                event.append (event.getLevelName)
                     .append(event.getName)
                     .append(" - ");
                return event.getContent;
        }
}


/*******************************************************************************

        A simple layout comprised only of time(ms), level, name, and message

*******************************************************************************/

public class SimpleTimerLayout : EventLayout
{
        /***********************************************************************
                
                Format outgoing message

        ***********************************************************************/

        char[] header (Event event)
        {
                char[20] tmp;

                event.append (toMilli (tmp, event.getTime))
                     .append (" ")
                     .append (event.getLevelName)
                     .append (event.getName)
                     .append (" - ");
                return event.getContent;
        }
}
