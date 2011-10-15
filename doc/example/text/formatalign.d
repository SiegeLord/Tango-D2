/**

  Example showing how the alignment component in a format string argument works.

  Put into public domain by Lars Ivar Igesund

*/

private import tango.io.Stdout;

void main()
{
    string myFName = "Johnny";
    Stdout.formatln("First Name = |{0,15}|", myFName);
    Stdout.formatln("Last Name  = |{0,15}|", "Foo de Bar");

    Stdout.formatln("First Name = |{0,-15}|", myFName);
    Stdout.formatln("Last Name  = |{0,-15}|", "Foo de Bar");

    Stdout.formatln("First name = |{0,5}|", myFName);
}
