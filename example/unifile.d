
private import  tango.io.Console,
                tango.io.UnicodeFile;

/*******************************************************************************

        Open a unicode file of an unknown encoding, and converts to UTF-8 
        for console display. UnicodeFile is templated for char/wchar/dchar
        target encodings

*******************************************************************************/

void main (char[][] args)
{
        if (args.length == 2)
           {
           // open a file for reading
           auto file = new UnicodeFile (args[1], Unicode.Unknown);

           // display on console
           Cout (file.read);
           }
        else
           Cout ("usage is: unifile filename");
}
