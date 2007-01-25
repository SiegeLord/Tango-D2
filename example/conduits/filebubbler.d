
private import  tango.io.Console,
                tango.io.FileScan,
                tango.io.FileConst;

/*******************************************************************************

        This example sweeps a named sub-directory tree for html files,
        and moves them to the current directory. The existing directory 
        hierarchy is flattened into a naming scheme where a '.' is used
        to replace the traditional path-separator

        Used by the Tango project to help manage renderings of the source 
        code.

*******************************************************************************/

void main(char[][] args)
{
        // sweep all html files in the specified subdir
        if (args.length is 2)
            foreach (proxy; (new FileScan).sweep (new FilePath(args[1]), ".html").files)
                     proxy.rename (new FilePath (FilePath.replace (proxy.toUtf8, FileConst.PathSeparatorChar, '.')));
        else
           Cout ("usage is filebubbler subdir").newline;
}

