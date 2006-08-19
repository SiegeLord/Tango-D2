
private import  tango.io.Console,
                tango.io.FileConduit,
                tango.io.MappedBuffer;

/*******************************************************************************

        open a file, map it into memory, and copy to console

*******************************************************************************/

void main (char[][] args)
{
        if (args.length == 2)
           {
           // open a file for reading
           auto mmap = new MappedBuffer (new FileConduit (args[1]));

           // copy content to console
           Cout (mmap.toUtf8);
           }
        else
           Cout ("usage is: mmap filename");
}
