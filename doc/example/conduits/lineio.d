
private import  tango.io.Console,
                tango.io.device.File;

private import  tango.io.stream.Lines;

/*******************************************************************************

        Read a file line-by-line, sending each one to the console. This
        illustrates how to bind a conduit to a stream iterator (iterators
        also support the binding of a buffer). Note that stream iterators
        are templated for char, wchar and dchar types.

*******************************************************************************/

void main (char[][] args)
{
        if (args.length is 2)
           {
           // open a file for reading
           scope file = new File (args[1]);

           // process file one line at a time
           foreach (line; new Lines!(char)(file))
                    Cout (line).newline;
           }
        else
           Cout ("usage: lineio filename").newline;
}