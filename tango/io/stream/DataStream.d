/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

        These classes represent a simple means of reading and writing
        discrete data types as binary values, with an option to invert
        the endian order of numeric values.

        Arrays are treated as untyped byte streams, with an optional
        length-prefix, and should otherwise be explicitly managed at
        the application level. We'll add additional support for arrays
        and aggregates in future.

*******************************************************************************/

module tango.io.stream.DataStream;

public import tango.io.stream.Data;

pragma (msg, "warning - io.stream.DataStream has been renamed io.stream.Data");
