/*******************************************************************************

        copyright:      Copyright (c) 2004 Tango group. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: July 2006


        Various char[] utilities

*******************************************************************************/

module rt.util.string;

private import rt.cImports: memcmp;

// convert uint to char[], within the given buffer
// Returns a valid slice of the populated buffer
char[] intToUtf8 (char[] tmp, uint val)
in {
   assert (tmp.length > 9, "atoi buffer should be 9 or more chars wide");
   }
body
{
    char* p = tmp.ptr + tmp.length;

    do {
       *--p = cast(char)((val % 10) + '0');
       } while (val /= 10);

    return tmp [(p - tmp.ptr) .. $];
}


// function to compare two strings
int stringCompare (char[] s1, char[] s2)
{
    auto len = s1.length;

    if (s2.length < len)
        len = s2.length;

    int result = memcmp(s1.ptr, s2.ptr, len);

    if (result == 0)
        result = (s1.length<s2.length)?-1:((s1.length==s2.length)?0:1);

    return result;
}
