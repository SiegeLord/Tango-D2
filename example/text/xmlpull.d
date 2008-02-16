import tango.io.File;
import tango.io.Stdout;
import tango.time.StopWatch;

import tango.text.xml.PullParser;

void benchmark (int iterations, char[] filename) 
{       
        char c1;
        static char c;
        StopWatch elapsed;
        
        auto file = new File (filename);
        auto content = cast(char[]) file.read;
        auto parser = new PullParser!(char) (content);

        elapsed.start;
        for (auto i=0; ++i < iterations;)
            {
            while (parser.next) 
                  {}
            parser.reset;
            }

        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}

void main() 
{       
        for (int i = 10; --i;)
             benchmark (5000, "hamlet.xml");       
}
