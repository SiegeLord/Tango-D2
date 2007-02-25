/*****************************************************

  Example that shows some simple file operations

  Put into public domain by Lars Ivar Igesund

*****************************************************/

import tango.io.Stdout;

import tango.io.FileProxy;

void main (char[][] args) 
{
    auto src = args[0] ~ ".d";
    auto dst = new FileProxy (args[0] ~ ".d.copy");

    Stdout.formatln ("copy file {} to {}", src, dst);
    dst.copy (src);
    assert (dst.exists);

    Stdout.formatln ("removing file {}",  dst);
    dst.remove;

    assert (dst.exists is false);
}
