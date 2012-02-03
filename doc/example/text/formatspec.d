/**

  Example showing how to use format specifier components in a format string's 
  argument.

  Put into public domain by Lars Ivar Igesund

*/

import tango.io.Stdout;
import tango.text.locale.Locale;

void main(){
    Stdout.layout = new Locale;
    double avogadros = 6.0221415e23;
    Stdout.formatln("I have {0:C} in cash.", 100);
    Stdout.formatln("Avogadro's number is {0:F}.", avogadros);
    Stdout.formatln("Avogadro's number (with alignment) is {0,34:F}.", avogadros);
    Stdout.formatln("Foo {:G}", 20);
}
