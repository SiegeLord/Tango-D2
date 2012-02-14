
private import  tango.io.Console,
                tango.io.device.File;

/*******************************************************************************

        open a file, and stream directly to console

*******************************************************************************/

void main (char[][] args)
{
        if (args.length is 2)
           {
           // open a file for reading
           auto fc = new File (args[1]);

           // stream directly to console
           Cout.stream.copy (fc);
           }
        else
           Cout ("usage is: filecopy filename").newline;
}
