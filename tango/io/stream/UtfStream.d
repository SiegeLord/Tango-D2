/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        UTF conversion streams, supporting cross-translation of char, wchar 
        and dchar variants. For supporting endian variations, configure the
        appropriate EndianStream upstream of this one (closer to the source)

*******************************************************************************/

module tango.io.stream.UtfStream;

public import tango.io.stream.Utf;

pragma (msg, "warning - io.stream.UtfStream has been renamed io.stream.Utf");

