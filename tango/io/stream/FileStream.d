/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.FileStream;

public import tango.io.device.File;

pragma (msg, "warning - io.stream.FileStream is deprecated. Please use io.device.File instead");

/*******************************************************************************

        Trivial wrappers around a File

*******************************************************************************/

alias File FileInput;

alias File FileOutput;
