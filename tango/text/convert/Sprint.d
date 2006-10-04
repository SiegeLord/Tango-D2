/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005

        author:         Kris

*******************************************************************************/

module tango.text.convert.Sprint;

private import  tango.core.Vararg;

private import  tango.text.convert.Format;

/******************************************************************************

        Constructs sprintf-style output. This is a replacement for the 
        vsprintf() family of functions, and writes it's output into a 
        lookaside buffer. 

        This is the stack-based version, used when heap allocation must
        be avoided ~ see Sprint for the class version

        ---
        // output buffer
        char[100]    tmp;

        SprintStruct sprint;
        sprint.ctor (tmp);

        // write text to the console
        Cout (sprint.format ("{0} green bottles, sitting on a wall\n", 10));
        ---

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
        alias format    opCall;

        protected T[]   buffer;
        protected T*    p, limit;

        /**********************************************************************

        **********************************************************************/

        void ctor (T[] dst)
        {
                p = buffer = dst;
                limit = p + buffer.length;
        }

        /**********************************************************************

        **********************************************************************/

        T[] format (T[] fmt, ...)
        {
                return format (fmt, _arguments, cast(va_list) _argptr);
        }

        /**********************************************************************

        **********************************************************************/

        T[] format (T[] fmt, TypeInfo[] arguments, va_list argptr)
        {
                p = buffer;
                return buffer [0 .. Formatter.format (&sink, arguments, argptr, fmt)];
        }

        /**********************************************************************

        **********************************************************************/

        private uint sink (T[] s)   
        {
                int len = s.length;
                if (p+len >= limit)
                    Formatter.error ("Sprint.sink : output buffer too small");
                
                p[0..len] = s;
                p += len;       
                return len;
        }
}


alias SprintStructT!(char) SprintStruct;



/******************************************************************************

        Constructs sprintf-style output. This is a replacement for the 
        vsprintf() family of functions, and writes it's output into a 
        lookaside buffer. 

        This is the class-based version, used when convenience is a
        factor ~ see SprintStruct for the stack-based version

        ---
        // create a Sprint instance
        auto sprint = new Sprint (100);

        // write text to the console
        Cout (sprint.format ("{0} green bottles, sitting on a wall\n", 10));
        ---

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
        alias format    opCall;

        protected T[]   buffer;
        protected T*    p, limit;

        /**********************************************************************

        **********************************************************************/

        this (int size)
        {
                p = buffer = new T[size];
                limit = p + buffer.length;
        }

        /**********************************************************************

        **********************************************************************/

        private uint sink (char[] s)   
        {
                int len = s.length;
                if (p+len >= limit)
                    Formatter.error ("Sprint.sink : output buffer too small");

                p[0..len] = s;
                p += len;       
                return len;
        }

        /**********************************************************************

        **********************************************************************/

        T[] format (T[] fmt, ...)
        {
                return format (fmt, _arguments, cast(va_list) _argptr);
        }

        /**********************************************************************

        **********************************************************************/

        T[] format (T[] fmt, TypeInfo[] arguments, va_list argptr)
        {
                p = buffer;
                return buffer [0 .. Formatter.format (&sink, arguments, argptr, fmt)];
        }
}

alias SprintClassT!(char) Sprint;

