private import  tango.io.Console,
                tango.io.FileScan;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. Thanks to Chris S for this
        
*******************************************************************************/

void main(char[][] args)
{       
        auto scan = new FileScan;
        
        scan ((args.length is 2) ? args[1] : ".", "d");

        Cout ("Directories:").newline;
        scan.directories ((FilePathView path) {Cout (path).newline;});

        Cout ("\nFiles:").newline;
        scan.files ((File file) {Cout (file).newline;});
}

