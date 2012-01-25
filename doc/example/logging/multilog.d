import tango.util.log.Log;
import tango.util.log.AppendFile;
import tango.util.log.AppendFiles;
import tango.util.log.AppendConsole;
import tango.util.log.LayoutChainsaw;

/*******************************************************************************

        Shows how to setup multiple appenders on logging tree

*******************************************************************************/

void main ()
{
        // set default logging level at the root
        auto log = Log.root;
        log.level = Level.Trace;

        // 10 logs, all with 10 mbs each
        log.add (new AppendFiles ("rolling.log", 9, 1024*1024*10));

        // a single file appender, with an XML layout
        log.add (new AppendFile ("single.log", new LayoutChainsaw));

        // console appender
        log.add (new AppendConsole);

        // log to all
        log.trace ("three-way logging");
}

