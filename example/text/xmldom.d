/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Kris Bell. All rights reserved.

        License:   BSD Style
        Authors:   Kris

*******************************************************************************/

import tango.io.File;
import tango.io.Stdout;
import tango.time.StopWatch;
import tango.text.xml.Document;

/*******************************************************************************

*******************************************************************************/

void bench (int iterations, char[] filename) 
{       
        StopWatch elapsed;

        auto doc = new Document!(char);
        auto content = cast(char[]) File(filename).read;

        elapsed.start;
        for (int i=0; i < iterations; i++)
             doc.parse (content);

        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}
        
/*******************************************************************************

*******************************************************************************/

void main()
{
        for (int i=20; --i;)
             bench (2000, "hamlet.xml");
}

