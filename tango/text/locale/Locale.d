/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Kris

        This is the Tango I18N gateway, which extends the basic Layout
        module with support for cuture- and region-specific formatting
        of numerics, date, time, and currency.

        Use as a standalone formatter in the same manner as Layout, or
        combine with other entities such as Stdout. To enable a French
        Stdout, do the following:
        ---
        Stdout.layout = new Locale (Culture.getCulture ("fr-FR"));
        ---
        
        Note that Stdout is a shared entity, so every usage of it will
        be affected by the above example. For applications supporting 
        multiple regions create multiple Locale instances instead, and 
        cache them in an appropriate manner.

        In addition to region-specific currency, date and time, Locale
        adds more sophisticated formatting option than Layout provides: 
        numeric digit placement using '#' formatting, for example, is 
        supported by Locale - along with placement of '$', '-', and '.'
        regional-specifics.

        Locale is currently utf8 only. Support for both Utf16 and utf32 
        may be enabled at a later time

******************************************************************************/

module tango.text.locale.Locale;

private import tango.text.locale.Core,
               tango.text.locale.Convert;

private import tango.util.time.DateTime;

private import tango.text.convert.Layout;

public  import tango.text.locale.Core : Culture;

/*******************************************************************************

        Locale-enabled wrapper around tango.text.convert.Layout

*******************************************************************************/

public class Locale : Layout!(char)
{
        private DateTimeFormat  dateFormat;
        private NumberFormat    numberFormat;

        /**********************************************************************

        **********************************************************************/

        this (IFormatService formatService = null)
        {
                numberFormat = NumberFormat.getInstance (formatService);
                dateFormat = DateTimeFormat.getInstance (formatService);
        }

        /***********************************************************************

        ***********************************************************************/

        protected override char[] unknown (char[] output, char[] format, TypeInfo type, Arg p)
        {
                switch (type.classinfo.name[9])
                       {
                            // Special case for DateTime.
                       case TypeCode.STRUCT:
                            if (type is typeid(DateTime))
                                return formatDateTime (output, *cast(DateTime*) p, format, dateFormat);

                       return type.toUtf8;

                       default:
                            break;
                       }

                return "{unhandled argument type: " ~ type.toUtf8 ~ '}';
        }

        /**********************************************************************

        **********************************************************************/

        protected override char[] integer (char[] output, long v, char[] alt, char format='d')
        {
                return formatInteger (output, v, alt, numberFormat);
        }

        /**********************************************************************

        **********************************************************************/

        protected override char[] floater (char[] output, real v, char[] format)
        {
                return formatDouble (output, v, format, numberFormat);
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Locale)
{
        import tango.io.Console;

        void main ()
        {
                auto layout = new Locale (Culture.getCulture ("fr-FR"));

                Cout (layout ("{:D}", DateTime.now)) ();
        }
}
