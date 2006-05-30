
private import  tango.io.Console,
                tango.io.FileConduit;

private import  tango.text.LineIterator;

/*******************************************************************************

        Read a file line-by-line, sending each one to the console. This
        illustrates how to bind a conduit to a text iterator. Iterators
        also support the binding of buffer and string instances.

        Note that iterators are templated for char, wchar and dchar ~ 
        this example uses char

*******************************************************************************/

void main (char[][] args)
{
        if (args.length == 2)
           {
           // open a file for reading
           auto file = new FileConduit (args[1]);

           // create an iterator and bind it to the file
           auto line = new LineIterator (file);

           // process file one line at a time
           while (line.next)
                  Cout (line.get) .newline;
           }
        else
           Cout ("usage: lineio filename");
}