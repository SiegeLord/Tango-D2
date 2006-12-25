private import  tango.io.Stdout,
                tango.io.FileScan;

/*******************************************************************************

        List ".d" files and enclosing folders visible via a directory given
        as a command-line argument. In this example we're also postponing a
        flush on Stdout until output is complete. Stdout is usually flushed
        on each invocation of newline or formatln, but here we're using '\n'
        to illustrate how to avoid flushing many individual lines
        
*******************************************************************************/

void main(char[][] args)
{       
        auto root = new FilePath (args.length < 2 ? "." : FilePath.asNormal(args[1]));
        Stdout.formatln ("Scanning '{0}'", root);

        auto scan = (new FileScan)(root, ".d");

        Stdout.format ("\n{0} Folders\n", scan.folders.length);
        foreach (file; scan.folders)
                 Stdout.format ("{0}\n", file);

        Stdout.format ("\n{0} Files\n", scan.files.length);
        foreach (file; scan.files)
                 Stdout.format ("{0}\n", file);

        Stdout.format ("\n{0} entries inspected\n", scan.inspected).flush;
}
