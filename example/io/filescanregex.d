/**************************************************************

    Example that use FileScan and Regex as a filter.

    Put into public domain by Lars Ivar Igesund

**************************************************************/

import tango.io.FileScan,
       tango.io.File,
       tango.text.Regex,
       tango.io.Stdout;

int main(char[][] args) {

    if (args.length < 2) {
        Stdout("Please pass a directory to search").newline; 
        return 0;
    }

    scope scan = new FileScan;
    scope regex =  Regex(r"\.(d|obj)$");

    scan(new FilePath(args[1]), (FileProxy fp, bool isDir) { 
            return (isDir || cast(bool)regex.test(fp.toUtf8())); 
    });
    
    foreach (File f; scan.files)
        Stdout(f.toUtf8).newline;

    return 0;
}
