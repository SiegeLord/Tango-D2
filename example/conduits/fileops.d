/*****************************************************

  Example that shows some simple file operations

  Put into public domain by Lars Ivar Igesund

*****************************************************/

import tango.io.File;
import tango.io.FilePath;
import tango.io.FileSystem;

void main() {

    auto src = new FilePath("fileops.d");
    auto dst = new FilePath("copiedfile.d");

    FileSystem.copy(src, dst);
    
    auto copiedfile = new File(dst);
    assert (copiedfile.isExisting);

    copiedfile.remove();

    assert (!copiedfile.isExisting);
}
