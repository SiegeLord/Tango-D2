/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Kris Bell. All rights reserved.

        License:   BSD Style
        Authors:   Kris

*******************************************************************************/

import tango.io.Stdout;
import tango.io.device.File;
import tango.time.StopWatch;
import tango.text.xml.Document;
import tango.text.xml.DocPrinter;

/*******************************************************************************

*******************************************************************************/

void bench (int iterations) 
{       
        StopWatch elapsed;

        auto doc = new Document!(char);
        auto content = cast (char[]) File.get ("hamlet.xml");

        elapsed.start;
        for (auto i=0; ++i < iterations;)
             doc.parse (content);

        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}
        
/*******************************************************************************

*******************************************************************************/

void main()
{
        for (int i=10; i--;)
             bench (2000);
}

