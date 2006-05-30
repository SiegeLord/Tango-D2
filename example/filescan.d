private import  tango.io.Stdout,
                tango.io.FileScan;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. Thanks to Chris S for this.
        
*******************************************************************************/

void main(char[][] args)
{       
        void files (File file)
        {
                Stdout (file) (CR);
        }

        void dirs (FilePath path)
        {
                Stdout (path) (CR);
        }

        char[] dir = (args.length == 2) ? args[1] : ".";

        FileScan scan = new FileScan;
        scan (dir, "d");

        Stdout ("Directories:\n"c);
        scan.directories (&dirs);

        Stdout ("\nFiles:\n"c);
        scan.files (&files);       
}

