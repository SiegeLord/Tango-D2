private import  tango.io.Console,
                tango.io.device.File;

/*******************************************************************************

        Concatenate a number of files onto a single destination

*******************************************************************************/

void main(char[][] args)
{
        if (args.length > 2)
           {
           // open the file for writing
           auto dst = new File (args[1], File.WriteCreate);

           // copy each file onto dst
           foreach (char[] arg; args[2..args.length])
                    dst.copy (new File(arg));

           // flush output and close
           dst.close;
           }
        else
           Cout ("usage: filecat target source1 ... sourceN").newline;
}
