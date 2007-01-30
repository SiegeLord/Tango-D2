/*****************************************************

  Example that shows some simple file operations

  Put into public domain by Lars Ivar Igesund

*****************************************************/

import tango.io.File;
import tango.io.FilePath;
import tango.io.FileConduit;
import tango.io.Stdout;

void main( char[][] args ) {

    auto src = new FileConduit( args[0] ~ ".d");
    auto dst = new FileConduit( args[0] ~ ".d.copy", FileConduit.ReadWriteCreate );
    Stdout.formatln( "copy file {0} to {1}",
            src.getPath.toUtf8,
            dst.getPath.toUtf8 );

    dst.copy(src);
    dst.close();
    
    auto copiedfile = new File(dst.getPath);
    assert (copiedfile.isExisting);

    Stdout.formatln( "removing file {0}",
            dst.getPath.toUtf8 );
    copiedfile.remove();

    assert (!copiedfile.isExisting);
}
