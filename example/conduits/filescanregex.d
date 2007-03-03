/**************************************************************

    Example that use FileScan and Regex as a filter.

    Put into public domain by Lars Ivar Igesund

**************************************************************/

import tango.io.File,
       tango.io.Stdout,
       tango.io.FileScan,
       tango.text.Regex;

void main(char[][] args) {
    if (args.length < 2) {
        Stdout("Please pass a directory to search").newline; 
        return;
    }

    scope scan = new FileScan;
    scope regex =  Regex(r"\.(d|obj)$");

    scan(args[1], delegate bool (FilePath fp, bool isDir) { 
         return isDir || regex.test(fp.toUtf8); 
    });
    

    foreach (file; scan.files)
             Stdout(file).newline;

    Stdout.formatln("Found {0} matches in {1} entries", scan.files.length, scan.inspected);
}
