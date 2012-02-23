/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Sep 2007: Initial release
        version:        Nov 2007: Added stream wrappers

        author:         Kris

*******************************************************************************/

module tango.text.convert.Format;

private import tango.text.convert.Layout;

/******************************************************************************

        Constructs a global utf8 instance of Layout

******************************************************************************/

public __gshared Layout!(char) Format;

shared static this()
{
        Format = Layout!(char).instance;
}

