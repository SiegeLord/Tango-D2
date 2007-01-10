/**************************************************************

    Example that use FileScan and Regex as a filter.

    Put into public domain by Lars Ivar Igesund

**************************************************************/

import tango.io.FileScan;
import tango.io.File;
import tango.text.Regex;
import tango.io.Stdout;

int main(char[][] args) {

    scope scan = new FileScan;
    scope regex =  Regex(r"\.(d|obj)$");

    scan(new FilePath(args[1]), (FileProxy fp, bool isdir) { 
            if (isdir) return true;
            return cast(bool)regex.test(fp.toUtf8()); 
    });
    
    foreach (File f; scan.files)
        Stdout(f.toUtf8).newline;

    return 0;
}
