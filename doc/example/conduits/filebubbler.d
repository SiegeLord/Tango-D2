
private import  tango.io.Console,
                tango.io.model.IFile,
                tango.io.vfs.FileFolder;

private import  Path = tango.io.Path;

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
        if (args.length !is 2)
            Cout ("usage is filebubbler subdir").newline;
        else
           foreach (file; (new FileFolder(args[1])).tree.catalog("*.html"))
                    Path.rename (file.toString(), Path.replace (file.toString().dup, FileConst.PathSeparatorChar, '.'));
}

