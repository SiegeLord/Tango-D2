
private import  tango.io.Console,
                tango.io.device.FileMap;

/*******************************************************************************

        open a file, map it into memory, and copy to console

*******************************************************************************/

void main (char[][] args)
{
        if (args.length is 2)
           {
           // open a file for reading
           auto mmap = new MappedFile (args[1]);

           // copy content to console
           Cout (cast(char[]) mmap.map) ();
           }
        else
           Cout ("usage is: mmap filename").newline;
}
