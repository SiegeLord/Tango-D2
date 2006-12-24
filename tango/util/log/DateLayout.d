/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.DateLayout;

private import  tango.util.log.Event,
                tango.util.log.Layout;

private import  tango.core.Epoch;

private import  tango.text.convert.Format;

/*******************************************************************************

        A layout with ISO-8601 date information prefixed to each message.
       
*******************************************************************************/

public class DateLayout : Layout
{
        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] header (Event event)
        {
                Epoch.Fields fields;

                // convert time to field values
                fields.setUtcTime (event.getEpochTime);
                                
                // format fields according to ISO-8601
                return Formatter.sprint (event.scratch.content, "{0:d4}-{1:d2}-{2:d2} {3:d2}:{4:d2}:{5:d2},{6:d3} {7,-6} {8} - ",
                                         fields.year, 
                                         fields.month, 
                                         fields.day, 
                                         fields.hour, 
                                         fields.min, 
                                         fields.sec, 
                                         event.getTime % 1000,
                                         event.getLevelName,
                                         event.getName
                                        );            
        }
}
