/*****************************************************

  Example that shows listing of children to a path.

*****************************************************/

import Path = tango.io.Path;
import tango.io.Stdout;

void main(char[][] args)
{
    if (args.length < 2) {
        Stdout("Please give a path as argument.").newline;
        return;
    }

    foreach(child; Path.children(args[1])) {
        if(child.folder)
           continue;

        char[] name = child.name;
        char[] path = child.path;
        ulong bytes = child.bytes;

        Stdout.formatln("Child {} has path \"{}\" and size is {} bytes", 
                        child.name, 
                        child.path,
                        child.bytes);
    }
}
