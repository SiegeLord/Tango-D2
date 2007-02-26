/******************************************************************************

        Example to format a locale-based time. For a default locale of 
        en-gb, this examples formats in the following manner:

        "Thu, 27 April 2006 18:20:47 +1"

******************************************************************************/

private import tango.io.Console;

private import tango.text.locale.Core;

void main ()
{
        char[64] tmp = void;

        Cout (DateTime.now.toUtf8 (tmp, "ddd, dd MMMM yyyy HH:mm:ss z")).newline;
}
