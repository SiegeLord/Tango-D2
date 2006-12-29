import ddep.Configuration;
import tango.io.Stdout;

void main()
{
    foreach(ver; getSetVersions()) {
        Stdout(ver)(" is set.").newline;
    }
}
