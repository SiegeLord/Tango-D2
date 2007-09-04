module vfsexample;

/**

  Example showing some simple VFS usage.

  Put into public domain by Lars Ivar Igesund

*/



import tango.io.vfs.VFS;
import tango.io.vfs.LocalFolder;
import tango.io.Stdout;

void main(char[][] args) {

    auto vfs = new VFS("_vfstmp");

    auto tangofolder = new LocalFolder("tango");
    vfs.mount(tangofolder, "tango");

    /*
    foreach(path; vfs.toList) {
        Stdout(path).newline;
    }
    */

    Stdout.format("\nFile count: {:u}", vfs.fileCount).newline;
    Stdout.format("Content size: {:u}", vfs.contentSize).newline;

    Stdout("Exists; ")(vfs.exists("/tango/io/FilePath.d")).newline;

    vfs.createFolder("/test");
    vfs.createFolder("/test/subdir");

    auto somedir = vfs.openFolder("/test/subdir");

    /*
    foreach (path; somedir.toList) {
        Stdout(path).newline;
    }
    */

    vfs.write("/test/subdir/mynew.file", vfs.read("/tango/io/Stdout.d"));

}
