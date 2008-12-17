/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.LineStream;

public import tango.io.stream.Lines;

public alias Lines!(char) LineInput;

pragma (msg, "warning - please use io.stream.Text (or io.stream.Lines) instead of io.stream.LineStream");