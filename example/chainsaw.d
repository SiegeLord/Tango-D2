import  tango.core.Thread;

import  tango.log.Log,
        tango.log.XmlLayout,
        tango.log.SocketAppender;

import  tango.net.Socket,
        tango.net.InternetAddress;


version (Win32)
         pragma (lib, "wsock32");


/*******************************************************************************

        Hooks up to Chainsaw for remote log capture. Chainsaw should be 
        configured to listen with an XMLSocketReciever

*******************************************************************************/

void main()
{
        // get a logger to represent this module
        auto logger = Log.getLogger ("example.chainsaw");

        // hook up an appender for XML output
        logger.addAppender (new SocketAppender (new InternetAddress("127.0.0.1", 4448), new XmlLayout));

        while (true)
              {
              logger.info ("Hello Chainsaw!");      
              Thread.sleep (Interval.second);
              }
}
