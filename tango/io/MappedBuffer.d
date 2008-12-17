/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: March 2004
        version:        Renamed and moved to tango.io.device: Nov 2008
        
        author:         Kris

*******************************************************************************/

module tango.io.MappedBuffer;

public import tango.io.device.FileMap;

public alias FileMap MappedBuffer;

pragma (msg, "warning - io.MappedBuffer has been replaced with io.device.FileMap");

