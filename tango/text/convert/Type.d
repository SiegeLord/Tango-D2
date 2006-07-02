/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2005

        author:         Kris

*******************************************************************************/

module tango.text.convert.Type;

struct Type
{
        // these could be replaced with TypeInfo if there were a dependable
        // means of extracting type from there (sans DLL issues, and name
        // differences across compilers)
        enum : uint
        {
                Void=0, Bool, Byte, UByte, Short, UShort, Int, UInt, Long, ULong, 
                Float, Double, Real, Utf8, Utf16, Utf32, Pointer, Obj,

                Raw=uint.max // non-utf type
        }

        // this could be extracted from TypeInfo
        static int[] widths = 
        [
                byte.sizeof,
                bool.sizeof,
                byte.sizeof,
                ubyte.sizeof,
                short.sizeof,
                ushort.sizeof,
                int.sizeof,
                uint.sizeof,
                long.sizeof,
                ulong.sizeof,
                float.sizeof,
                double.sizeof,
                real.sizeof,
                char.sizeof,
                wchar.sizeof,
                dchar.sizeof,
                (void*).sizeof,
                (Object*).sizeof,
        ];

        // 
        static TypeInfo[] revert = 
        [
                typeid(void), // byte.sizeof,
                typeid(bool), // bool.sizeof,
                typeid(byte), // byte.sizeof,
                typeid(ubyte), // ubyte.sizeof,
                typeid(short), // short.sizeof,
                typeid(ushort), // ushort.sizeof,
                typeid(int), // int.sizeof,
                typeid(uint), // uint.sizeof,
                typeid(long), // long.sizeof,
                typeid(ulong), // ulong.sizeof,
                typeid(float), // float.sizeof,
                typeid(double), // double.sizeof,
                typeid(real), // real.sizeof,
                typeid(char), // char.sizeof,
                typeid(wchar), // wchar.sizeof,
                typeid(dchar), // dchar.sizeof,
                typeid(void*), // (void*).sizeof,
                typeid(Object), // (Object*).sizeof,
        ];


        // a mixin template for configuring a default string type
        template TextType(T)
        {
                static if (is (T == char))
                           protected const int TextType = Type.Utf8;
                static if (is (T == wchar))
                           protected const int TextType = Type.Utf16;
                static if (is (T == dchar))
                           protected const int TextType = Type.Utf32;
        }
}


