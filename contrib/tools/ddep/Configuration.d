module ddep.Configuration;

import tango.io.protocol.DisplayWriter;
import tango.io.FileConduit;
import tango.io.Stdout;
import tango.io.File;
import tango.text.stream.LineIterator;
import tango.sys.Process;

const char[][] VERSION_IDS = ["DigitalMars", "X86", "PPC", "AMD64", "PPC64", 
                              "Windows", "Win32", "Win64", "linux", "darwin",
                              "Unix", "unix", "Posix", "LittleEndian", "BigEndian",
                              "D_InlineAsm", "GNU", "GCC", "TDC"];

char[][] getSetVersions()
{
    char[][] ids;
    auto fc = new FileConduit("versions_tmp.d", FileConduit.WriteAppending);
    auto writer = new DisplayWriter(fc);

    foreach (id; VERSION_IDS) {
        writer("version("c)(id)(") pragma(msg,\""c)(id)("\");"c).newline;
    }
    writer();
    fc.close();

    auto proc = new Process("dmd", "-c", "versions_tmp.d");

    proc.execute();

    foreach (i, line; new LineIterator!(char)(proc.stdout))
    {
        ids ~= line;
    }

    auto file = new File("versions_tmp.d");
    file.remove();

    return ids;
}
