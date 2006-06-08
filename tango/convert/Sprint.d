/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: Nov 2005

        author:         Kris

*******************************************************************************/

module tango.convert.Sprint;

private import  tango.core.vararg;

private import  tango.convert.Type,
                tango.convert.Format,
                tango.convert.Unicode;

/******************************************************************************

        Constructs sprintf-style output. This is a replacement for the 
        vsprintf() family of functions, and writes it's output into a 
        lookaside buffer. 

        This is the stack-based version, used when heap allocation must
        be avoided ~ see Sprint for the class version

        @code
        // output buffer
        char[100]    tmp;

        SprintStruct sprint;
        sprint.ctor (tmp);

        // write text to the console
        Cout (sprint ("%d green bottles, sitting on a wall\n", 10));
        @endcode

        State is maintained on the stack only, making this thread-safe. 
        You may supply a workspace buffer as an optional initialization 
        argument, which should typically also be allocated on the stack.

        Note that Sprint is templated, and can be instantiated for wide
        chars through a SprintStructTemplate!(dchar) or wchar. The wide
        versions differ in that both the output and the format-string
        are of the target type. Variadic string arguments are transcoded 
        appropriately.

        Floating-point support is optional. The second ctor argument is
        for hooking up an appropriate formatter, such as Double.format
        or DGDouble.format.

        See Format.parse() for the list of format specifiers.

******************************************************************************/

struct SprintStructT(T)
{
        package alias FormatStructT!(T) Format;

        private   Unicode.Into!(T) into;
        protected Format           format;
        protected T[128]           tmp;
        protected T[]              buffer;
        protected T*               p, limit;

        mixin Type.TextType!(T);

        /**********************************************************************

        **********************************************************************/

        void ctor (T[] dst, Format.DblFormat df = null, T[] workspace = null)
        {
                format.ctor (&sink, null, workspace.length ? workspace : tmp, df);
                p = buffer = dst;
                limit = p + buffer.length;
        }

        /**********************************************************************

        **********************************************************************/

        private uint sink (void[] v, uint type)   
        {
                auto s = cast(T[]) into.convert (v, type);

//                if (type != TextType)
//                    format.error ("Sprint.sink : struct version does not transcode");
//                auto s = cast(T[]) v;

                int len = s.length;
                if (p+len >= limit)
                    format.error ("Sprint.sink : output buffer too small");
                
                p[0..len] = s[0..len];
                p += len;       
                return len;
        }

        /**********************************************************************

        **********************************************************************/

        T[] opCall (T[] fmt, ...)
        {
                p = buffer;
                return buffer [0 .. format (fmt, _arguments, _argptr)];
        }
}


alias SprintStructT!(char) SprintStruct;



/******************************************************************************

        Constructs sprintf-style output. This is a replacement for the 
        vsprintf() family of functions, and writes it's output into a 
        lookaside buffer. 

        This is the class-based version, used when convenience is a
        factor ~ see SprintStruct for the stack-based version

        @code
        // create a Sprint instance
        Sprint sprint = new Sprint (100);

        // write text to the console
        Cout (sprint ("%d green bottles, sitting on a wall\n", 10));
        @endcode

        This can be really handy when you wish to format text for 
        a Logger. Please note that the class itself is stateful, and 
        therefore a single instance is not shareable across multiple 
        threads. 
        
        Note that Sprint is templated, and can be instantiated for wide
        chars through a SprintStructTemplate!(dchar) or wchar. The wide
        versions differ in that both the output and the format-string
        are of the target type. Variadic string arguments are transcoded 
        appropriately.

        Floating-point support is optional. The second ctor argument is
        for hooking up an appropriate formatter, such as Double.format
        or DGDouble.format.

        See Format.parse() for the list of format specifiers.

******************************************************************************/

class SprintClassT(T)
{
        package alias FormatStructT!(T) Format;

        private Unicode.Into!(T) into;
        private Format           format;
        private T[128]           tmp;
        private T[]              buffer;
        private T*               p, limit;

        /**********************************************************************

        **********************************************************************/

        this (int size, Format.DblFormat df = null, T[] workspace = null)
        {
                format.ctor (&sink, null, workspace.length ? workspace : tmp, df);
                p = buffer = new T[size];
                limit = p + buffer.length;
        }

        /**********************************************************************

        **********************************************************************/

        private uint sink (void[] v, uint type)   
        {
                auto s = cast(T[]) into.convert (v, type);

                int len = s.length;
                if (p+len >= limit)
                    format.error ("Sprint.sink : output buffer too small");

                p[0..len] = s[0..len];
                p += len;       
                return len;
        }

        /**********************************************************************

        **********************************************************************/

        T[] opCall (T[] fmt, ...)
        {
                p = buffer;
                return buffer [0 .. format (fmt, _arguments, _argptr)];
        }
}

alias SprintClassT!(char) Sprint;

