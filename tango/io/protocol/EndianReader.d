/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         Kris

*******************************************************************************/

module tango.io.protocol.EndianReader;

public  import  tango.io.protocol.Reader;

private import  tango.text.convert.Type;

private import  tango.core.ByteSwap;

/*******************************************************************************

*******************************************************************************/

class EndianReader : Reader
{
        /***********************************************************************

                Construct EndianWriter upon the given IBuffer

        ***********************************************************************/

        this (IBuffer buffer)
        {
                super (buffer);
        }

        /***********************************************************************

        ***********************************************************************/

        protected override uint read (void* dst, uint bytes, uint type)
        {
                super.read (dst, bytes, type);

                switch (type)
                       {
                       case Type.Short:
                       case Type.UShort:
                       case Type.Utf16:
                            ByteSwap.swap16 (dst, bytes);
                            break;

                       case Type.Int:
                       case Type.UInt:
                       case Type.Float:
                       case Type.Utf32:
                            ByteSwap.swap32 (dst, bytes);
                            break;

                       case Type.Long:
                       case Type.ULong:
                       case Type.Double:
                            ByteSwap.swap64 (dst, bytes);
                            break;

                       case Type.Real:
                            ByteSwap.swap80 (dst, bytes);
                            break;

                       default:
                            break;
                       }

                return bytes;
        }
}
