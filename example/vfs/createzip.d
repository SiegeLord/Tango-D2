module createzip;

import tango.io.archive.Zip;
import tango.io.FileScan;
import tango.io.Stdout;

/******************************************************************************

  Simple example where the current folder is recursively scanned for .d files 
  before they are zipped into tmp.zip.

  Written and put into the public domain by Piotr Modzelevski.

******************************************************************************/

void main(){
    auto scan = (new FileScan)(".", ".d");
    char[][] files;
    foreach (file; scan.files) 
        files ~= file.toString;

    createArchive("tmp.zip", Method.Deflate, files);
}
