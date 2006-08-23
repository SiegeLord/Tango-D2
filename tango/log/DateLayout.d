/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.DateLayout;

private import  tango.log.Event,
                tango.log.Layout;

private import  tango.core.Epoch;

private import  tango.text.convert.Sprint;

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
                                
                // point formatter at the output buffer
                SprintStruct sprint;
                sprint.ctor (event.scratch.content);
/+        
                // format fields according to ISO-8601
                return sprint ("%04d-%02d-%02d %02d:%02d:%02d,%03d %-6s %s - ",
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
+/
                // format fields according to ISO-8601
                return sprint ("{0:d4}-{1:d2}-{2:d2} {3:d2}:{4:d2}:{5:d2},{6:d3} {7,-6} {8} - ",
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
