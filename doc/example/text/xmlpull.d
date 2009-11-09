import tango.io.Stdout;
import tango.io.device.File;
import tango.time.StopWatch;
import tango.text.xml.PullParser;

void benchmark (int iterations) 
{       
        StopWatch elapsed;
        
        auto content = cast (char[]) File.get ("hamlet.xml");
        auto parser = new PullParser!(char) (content);

        uint j;
        elapsed.start;
        for (auto i=0; ++i < iterations;)
            {
            while (parser.next) {++j;}
            parser.reset;
            }
        Stdout.formatln ("{} MB/s, {} tokens", (content.length * iterations) / (elapsed.stop * (1024 * 1024)), j);
}


void main() 
{      
        // uncomment me, and try again ... 
        //char[] s = null;
        for (int i = 10; --i;)
             benchmark (2000);       
}

