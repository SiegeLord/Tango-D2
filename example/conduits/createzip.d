module createzip;

import tango.io.compress.Zip;
import tango.io.vfs.FileFolder;
import tango.io.FileSystem;

import tango.io.Stdout;

/******************************************************************************

  Simple example where the current folder is recursively scanned for .d files 
  before they are zipped into tmp.zip.

  Written and put into the public domain by Piotr Modzelevski.

******************************************************************************/

void main()
{
        char[][] files;
        auto root = new FileFolder (".");
        foreach (file; root.tree.catalog ("*.d")) {
            auto f = FileSystem.toAbsolute(file.toString);

                 files ~= f;//.toString;
                 Stdout(f).newline;
        }

        createArchive("tmp.zip", Method.Deflate, files);
}
