/*******************************************************************************

        @file DateLayout.d

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

module tango.log.DateLayout;

private import  tango.log.Event,
                tango.log.Layout;

private import  tango.core.Epoch;

private import  tango.convert.Sprint;

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
        }
}
