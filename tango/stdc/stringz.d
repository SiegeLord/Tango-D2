/*******************************************************************************

        copyright:      Copyright (c) 2006 Keinfarbton. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2006

        author:         Keinfarbton & Kris

*******************************************************************************/

module tango.stdc.stringz;

/*********************************
 * Convert array of chars to a C-style 0 terminated string.
 * Providing a tmp will use that instead of the heap, where
 * appropriate.
 * 
 * Warning, don't read from the memory pointed to in the tmp variable after calling this function.
 */

inout(char)* toStringz (inout(char)[] s, char[] tmp=null)
{
        auto len = s.length;
        if (s.ptr)
        {
            if (len is 0)
            {
                s = cast(inout(char)[])("\0".dup);
            }
            else if (s[len-1] != 0)
            {
                  if (tmp.length <= len)
                      tmp = new char[len+1];
                  tmp [0..len] = s[];
                  tmp [len] = 0;
                  s = cast(inout(char)[])tmp;
            }
        }
        return s.ptr;
}

/*********************************
 * Convert a series of char[] to C-style 0 terminated strings, using 
 * tmp as a workspace and dst as a place to put the resulting char*'s.
 * This is handy for efficiently converting multiple strings at once.
 *
 * Returns a populated slice of dst
 * 
 * Warning, don't read from the memory pointed to in the tmp variable after calling this function.
 *
 * Since: 0.99.7
 */

inout(char)*[] toStringz (char[] tmp, inout(char)*[] dst, inout(char)[][] strings...)
{
        assert (dst.length >= strings.length);

        auto len = strings.length;
        foreach (s; strings)
                 len += s.length;
        if (tmp.length < len)
            tmp.length = len;

        foreach (i, s; strings)
                {
                dst[i] = toStringz (s, tmp);
                tmp = tmp [s.length + 1 .. len];
                }
        return dst [0 .. strings.length];
}

/*********************************
 * Convert a C-style 0 terminated string to an array of char
 */

inout(char)[] fromStringz (inout(char)* s)
{
        return s ? s[0 .. strlenz(s)] : null;
}

/*********************************
 * Convert array of wchars s[] to a C-style 0 terminated string.
 */

inout(wchar)* toString16z (inout(wchar)[] s)
{
        if (s.ptr)
            if (! (s.length && s[$-1] is 0))
                   s = cast(inout(wchar)[])(s ~ "\0"w);
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of wchar
 */

inout(wchar)[] fromString16z (inout(wchar)* s)
{
        return s ? s[0 .. strlenz(s)] : null;
}

/*********************************
 * Convert array of dchars s[] to a C-style 0 terminated string.
 */

inout(dchar)* toString32z (inout(dchar)[] s)
{
        if (s.ptr)
            if (! (s.length && s[$-1] is 0))
                   s = cast(inout(dchar)[])(s ~ "\0"d);
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of dchar
 */

inout(dchar)[] fromString32z (inout(dchar)* s)
{
        return s ? s[0 .. strlenz(s)] : null;
}

/*********************************
 * portable strlen
 */

size_t strlenz(T) (const(T)* s)
{
        size_t i;

        if (s)
            while (*s++)
                   ++i;
        return i;
}



debug (UnitTest)
{
        import tango.stdc.stdio;

        unittest
        {
        debug(string) printf("stdc.stringz.unittest\n");

        const(char)* p = toStringz("foo");
        assert(strlenz(p) == 3);
        const(char)[] foo = "abbzxyzzy";
        p = toStringz(foo[3..5]);
        assert(strlenz(p) == 2);

        const(char)[] test = "\0";
        p = toStringz(test);
        assert(*p == 0);
        assert(p == test.ptr);
        }
}

