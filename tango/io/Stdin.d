/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2011: Initial release

        author:         Kris

*******************************************************************************/

module tango.io.Stdin;

private import  tango.io.Console,
                tango.io.model.IConduit;

/*******************************************************************************

        Construct Stdin when this module is loaded

*******************************************************************************/

public static __gshared InputStream Stdin;
public alias Stdin                  stdin;       /// alternative

static this()
{
    Stdin = Cin.stream;
}
