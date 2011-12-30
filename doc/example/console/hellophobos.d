/**
 * Hello World in combination with the two libarys
 *
 * This illustrates how to use tango and phobos side by side. 
 *
 * Console I/O in Tango is UTF-8 across both linux and Win32. The
 * conversion between various unicode representations is handled
 * by higher level constructs, such as Stdout and Stderr
 */
module hellophobos;

import tango.io.Console;
import std.stdio;

void main()
{
    // long form
    std.stdio.writeln("Hello Phobos!");
    tango.io.Console.Cout("Hello Tango!").newline;
 
    // short form
    writeln("Hello Phobos!");
    Cout("Hello Tango!").newline;
}
