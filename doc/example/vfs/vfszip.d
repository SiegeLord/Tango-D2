module vfszip;

import tango.io.vfs.ZipFolder;
import tango.io.Stdout;

/******************************************************************************

  VFS example that reads the file tmp.zip or one given as an argument.

  The example prints the file count in the zip, the content size, and then
  outputs the content itself. Only recommended for small zips with text files.

  Written and put into the public domain by Piotr Modzelewski.

******************************************************************************/

void main(char[][] args)
{
    const(char)[] zipname;
    if (args.length == 2)
        zipname = args[1];
    else
        zipname = "tmp.zip";

    auto archive = new ZipFolder(zipname);
    auto info = archive.self;

    Stdout.formatln ("file count: {}", info.files);
    Stdout.formatln ("content size (of files): {}", info.bytes);

    foreach (file; archive.tree.catalog){
        Stdout(file.name).newline;
        Stdout.stream.copy( file.input );
    }
}
