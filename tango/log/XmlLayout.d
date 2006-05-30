/*******************************************************************************

        @file XmlLayout.d

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

module tango.log.XmlLayout;

private import  tango.log.Event,
                tango.log.Layout;

/*******************************************************************************

        A layout with XML output conforming to Log4J specs.
       
*******************************************************************************/

public class XmlLayout : Layout
{
        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] header (Event event)
        {
                char[20] tmp;

                event.append ("<log4j:event logger=\"")
                     .append (event.getName)
                     .append ("\" timestamp=\"")
                     .append (ultoa (tmp, event.getEpochTime))
                     .append ("\" level=\"")
                     .append (event.getLevelName [0..length-1])
                     .append ("\" thread=\"unknown\">\r\n<log4j:message><![CDATA[");

                return event.getContent;
        }


        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] footer (Event event)
        {       
                event.scratch.length = 0;
                event.append ("]]></log4j:message>\r\n<log4j:properties><log4j:data name=\"application\" value=\"")
                     .append (event.getHierarchy.getName)
                     .append ("\"/><log4j:data name=\"hostname\" value=\"")
                     .append (event.getHierarchy.getAddress)
                     .append ("\"/></log4j:properties></log4j:event>\r\n");

                return event.getContent;
        }
}


