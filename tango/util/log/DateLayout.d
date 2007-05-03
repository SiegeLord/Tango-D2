/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.DateLayout;

private import  tango.util.log.Event,
                tango.util.log.Layout;

private import  tango.text.Util;

private import  tango.util.time.Utc,
                tango.util.time.Date;

private import  Int = tango.text.convert.Integer;

/*******************************************************************************

        A layout with ISO-8601 date information prefixed to each message
       
*******************************************************************************/

public class DateLayout : Layout
{
        private bool localTime;

        private static char[6] spaces = ' ';

        /***********************************************************************
        
                Ctor with indicator for local vs UTC time. Default is 
                local time.
                        
        ***********************************************************************/

        this (bool localTime = true)
        {
                this.localTime = localTime;
        }

        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] header (Event event)
        {
                char[] level = event.getLevelName;
                
                // convert time to field values
                Date date;
                auto time = event.getEpochTime;
                if (localTime)
                    date.setLocal (time);
                else
                   date.set (time);
                                
                // format date according to ISO-8601 (lightweight formatter)
                char[20] tmp = void;
                return layout (event.scratch.content, "%0-%1-%2 %3:%4:%5,%6 %7%8 %9 - ", 
                               convert (tmp[0..4],   date.year),
                               convert (tmp[4..6],   date.month),
                               convert (tmp[6..8],   date.day),
                               convert (tmp[8..10],  date.hour),
                               convert (tmp[10..12], date.min),
                               convert (tmp[12..14], date.sec),
                               convert (tmp[14..17], date.ms),
                               spaces [0 .. $-level.length],
                               level,
                               event.getName
                              );
        }
        
        /**********************************************************************

                Convert an integer to a zero prefixed text representation

        **********************************************************************/

        private char[] convert (char[] tmp, int i)
        {
                return Int.format (tmp, cast(long) i, Int.Style.Unsigned, Int.Flags.Zero);
        }
}
