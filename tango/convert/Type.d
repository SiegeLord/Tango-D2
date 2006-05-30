/*******************************************************************************

        @file Type.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version; April 2005
                        Moved to tango.convert; November 2005

        @author         Kris


*******************************************************************************/

module tango.convert.Type;

struct Type
{
        // these could be replaced with TypeInfo if there were a dependable
        // means of extracting type from there (sans DLL issues, and name
        // differences across compilers)
        enum : uint
        {
                Void=0, Bool, Byte, UByte, Short, UShort, Int, UInt, Long, ULong, 
                Float, Double, Real, Utf8, Utf16, Utf32, Pointer,

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


