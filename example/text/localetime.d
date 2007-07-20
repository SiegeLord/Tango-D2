/******************************************************************************

        Example to format a locale-based time. For a default locale of 
        en-gb, this examples formats in the following manner:

        "Thu, 27 April 2006 18:20:47 +1"

******************************************************************************/

private import tango.io.Console;

private import tango.util.time.DateTime;

private import tango.text.locale.Locale;

void main ()
{
        auto layout = new Locale;

        Cout (layout ("{:ddd, dd MMMM yyyy HH:mm:ss z}", DateTime.now)).newline;
}
