/**************************************************************

    Example that use FileScan and Regex as a filter.

    Put into public domain by Lars Ivar Igesund

**************************************************************/

import tango.io.FileScan,
       tango.io.File,
       tango.text.Regex,
       tango.io.Stdout;

int main(char[][] args) {

    ulong checked = 0;
    ulong found = 0;
    
    if (args.length < 2) {
        Stdout("Please pass a directory to search").newline; 
        return 0;
    }

    scope scan = new FileScan;
    scope regex =  Regex(r"\.(d|obj)$");

    scan(new FilePath(args[1]), delegate bool (FileProxy fp, bool isDir) { 
            checked++;
            return isDir || regex.test(fp.toUtf8); 
    });
    

    foreach (File f; scan.files) {
        found++;
        Stdout(f.toUtf8).newline;
    }

    Stdout.format("Checked {0} files", checked).newline;
    Stdout.format("Found {0} matches", found).newline;

    return 0;
}
