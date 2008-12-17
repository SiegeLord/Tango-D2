/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        Streams for swapping endian-order. The stream is treated as a set
        of same-sized elements. Note that partial elements are not mutated

*******************************************************************************/

module tango.io.stream.EndianStream;

public import tango.io.stream.Endian;

pragma (msg, "warning - io.stream.EndianStream has been renamed io.stream.Endian");

