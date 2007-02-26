/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Kris

******************************************************************************/

module tango.text.locale.Locale;

private import tango.text.locale.Core,
               tango.text.locale.Convert;

private import tango.text.convert.Layout;

/*******************************************************************************

        Platform issues ...

*******************************************************************************/

version (DigitalMars)
         private alias void* Arg;
     else
        private alias char* Arg;

/*******************************************************************************

        Locale-enabled wrapper around tango.text.convert.Layout

*******************************************************************************/

public class Locale
{
        private Layout!(char)   layout_;
        private DateTimeFormat  dateFormat;
        private NumberFormat    numberFormat;
        private IFormatService  formatService;

        /**********************************************************************

        **********************************************************************/

        this (IFormatService formatService = null)
        {
                this (new Layout!(char));
        }

        /**********************************************************************

        **********************************************************************/

        this (Layout!(char) layout, IFormatService formatService = null)
        {
                layout_ = layout;

                layout.config.floater = &floater;
                layout.config.integer = &integer;
                layout.config.unknown = &unknown;

                numberFormat = NumberFormat.getInstance (formatService);
                dateFormat = DateTimeFormat.getInstance (formatService);
        }

        /**********************************************************************

                Return the associated layout instance

        **********************************************************************/

        final Layout!(char) layout ()
        {
                return layout_;
        }

        /***********************************************************************

        ***********************************************************************/

        private char[] unknown (char[] output, char[] format, TypeInfo type, Arg p)
        {
                switch (type.classinfo.name[9])
                       {
                            // Special case for DateTime.
                       case TypeCode.STRUCT:
                            if (type is typeid(DateTime))
                                return formatDateTime (output, *cast(DateTime*) p, format, dateFormat);

                            return type.toUtf8;
                       }

                return "{unhandled argument type: " ~ type.toUtf8 ~ '}';
        }

        /**********************************************************************

        **********************************************************************/

        private char[] integer (char[] output, long v, char[] format)
        {
                return formatInteger (output, v, format, numberFormat);
        }

        /**********************************************************************

        **********************************************************************/

        private char[] floater (char[] output, real v, char[] format)
        {
                return formatDouble (output, v, format, numberFormat);
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Test1)
{
        import tango.io.Console;

        void main ()
        {
                auto layout = (new Locale).layout;
                Cout (layout ("{:G} {} bottles", DateTime.now, "green")) ();
        }
}
