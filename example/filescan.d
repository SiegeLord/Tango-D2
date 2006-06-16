private import  tango.io.Console,
                tango.io.FileScan;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. Thanks to Chris S for this.
        
*******************************************************************************/

void main(char[][] args)
{       
        void files (File file)
        {
                Cout (file.toString).newline;
        }

        void dirs (FilePath path)
        {
                Cout (path.toString).newline;
        }

        char[] dir = (args.length == 2) ? args[1] : ".";

        FileScan scan = new FileScan;
        scan (dir, "d");

        Cout ("Directories:").newline;
        scan.directories (&dirs);

        Cout ("\nFiles:").newline;
        scan.files (&files);       
}

