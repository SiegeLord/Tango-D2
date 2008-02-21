import tango.io.Stdout;
import tango.time.StopWatch;

import tango.text.xml.PullParser;

void benchmark (int iterations, char[] filename) 
{       
        StopWatch elapsed;
        
        auto content = import ("hamlet.xml");
        auto parser = new PullParser!(char) (content);

        elapsed.start;
        for (auto i=0; ++i < iterations;)
            {
            while (parser.next) {}
            parser.reset;
            }
        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}

void main() 
{       
        for (int i = 10; --i;)
             benchmark (2000, "hamlet.xml");       
}
