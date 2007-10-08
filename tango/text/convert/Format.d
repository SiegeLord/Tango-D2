/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Sep 2007: Initial release

        author:         Kris

*******************************************************************************/

module tango.text.convert.Format;

private import tango.text.convert.Layout;

/******************************************************************************

        A public utf8 Layout instance

******************************************************************************/

public Layout!(char) Format;

/******************************************************************************

        Constructs a global utf8 instance of Layout

******************************************************************************/

static this()
{
        Format = new Layout!(char);
}


debug (Format)
{
        import tango.io.Console;

        void main()
        {
                char[200] tmp=void;
                Cout (Format.sprint (tmp, "foo {}", "bar")).newline;
        }
}
