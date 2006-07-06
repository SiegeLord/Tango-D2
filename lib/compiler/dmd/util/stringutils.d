module util.string;

private extern (C) int memcmp (void*, void*, int);

// convert uint to char[], within the given buffer 
// Returns a valid slice of the populated buffer
char[] intToString (char[] tmp, uint val)
in {
   assert (tmp.length > 9, "atoi buffer should be 9 or more chars wide");
   }
body
{
    char* p = tmp.ptr + tmp.length;

    do {
       *--p = (val % 10) + '0';
       } while (val /= 10);

    return tmp [(p - tmp.ptr) .. $];
}


// function to compare two strings
int stringCompare (char[] s1, char[] s2)
{
    auto len = s1.length;

    if (s2.length < len)
        len = s2.length;

    int result = memcmp(s1, s2, len);

    if (result == 0)
        result = cast(int)s1.length - cast(int)s2.length;

    return result;
}
