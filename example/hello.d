/*******************************************************************************

        Hello World using tango.io

        This illustrates bare console output, with no fancy formatting. 
        One could use the Print module instead, which provides printf()
        formatting support.

        Console I/O in Mango is UTF-8 across both linux and Win32. The
        conversion between various unicode representations is handled
        by higher level constructs, including Print, Stdin, and Stdout.

        Note that Cerr is tied to the console error output, and Cin is
        tied to the console input. 

*******************************************************************************/

import tango.io.Console;

void main()
{
        Cout ("hello, sweetheart \u263a").newline;
}
