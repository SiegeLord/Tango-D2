/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Kris

*******************************************************************************/

module tango.io.FileConduit;

public import tango.io.device.File;

public alias File FileConduit;

pragma (msg, "warning - io.FileConduit has been renamed io.device.File");
