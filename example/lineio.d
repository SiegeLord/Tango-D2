
private import  tango.io.Console,
                tango.io.FileConduit;

private import  tango.text.stream.LineIterator;

/*******************************************************************************

        Read a file line-by-line, sending each one to the console. This
        illustrates how to bind a conduit to a text iterator. Iterators
        also support the binding of buffer and string instances.

        Note that iterators are templated for char, wchar and dchar ~ 
        this example uses char

*******************************************************************************/

void main (char[][] args)
{
        if (args.length is 2)
           {
           // open a file for reading
           auto file = new FileConduit (args[1]);

           // process file one line at a time
           foreach (line; new LineIterator!(char)(file))
                    Cout (line).newline;
           }
        else
           Cout ("usage: lineio filename").newline;
}