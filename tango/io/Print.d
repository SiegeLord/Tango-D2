/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Separated from Stdout 
                
        author:         Kris

*******************************************************************************/

module tango.io.Print;

public import tango.io.stream.Format;

public alias FormatOutput!(char) Print;

pragma (msg, "warning - io.Print has been replaced with io.stream.Format");
