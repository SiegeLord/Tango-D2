/*******************************************************************************

        copyright:      Copyright (c) 2006 Keinfarbton. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2006

        author:         Keinfarbton

*******************************************************************************/

module tango.stdc.stringz;

/*********************************
 * Convert array of chars s[] to a C-style 0 terminated string.
 */

char* toUtf8z (char[] s)
{
        if (s.ptr)
            s ~= '\0';
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of char
 */

char[] fromUtf8z (char* s)
{
        return s ? s[0 .. strlenz(s)] : null;
}

/*********************************
 * Convert array of wchars s[] to a C-style 0 terminated string.
 */

wchar* toUtf16z (wchar[] s)
{
        if (s.ptr)
            s ~= "\0"w;
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of wchar
 */

wchar[] fromUtf16z (wchar* s)
{
        return s ? s[0 .. strlenz(s)] : null;
}

/*********************************
 * portable strlen
 */

size_t strlenz(T) (T* s)
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

        char* p = toUtf8z("foo");
        assert(strlenz(p) == 3);
        char foo[] = "abbzxyzzy";
        p = toUtf8z(foo[3..5]);
        assert(strlenz(p) == 2);

        char[] test = "";
        p = toUtf8z(test);
        assert(*p == 0);
        }
}

