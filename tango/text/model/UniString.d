/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005
        
        author:         Kris

*******************************************************************************/

module tango.text.model.UniString;

/*******************************************************************************

        A string abstraction that converts to anything

*******************************************************************************/

class UniString
{
        abstract char[]  utf8  (char[]  dst = null);

        abstract wchar[] utf16 (wchar[] dst = null);

        abstract dchar[] utf32 (dchar[] dst = null);

	abstract uint getEncoding();
}

