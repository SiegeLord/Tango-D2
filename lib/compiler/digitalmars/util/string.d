/* Author:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 */

module util.string;

private import tango.stdc.string;
private import tango.stdc.stdio;

extern (C) int memicmp(char *, char *, uint);

/* ************* Constants *************** */

const char[16] hexdigits = "0123456789ABCDEF";			/// 0..9A..F
const char[10] digits    = "0123456789";			    /// 0..9
const char[8]  octdigits = "01234567";				    /// 0..7
const char[26] lowercase = "abcdefghijklmnopqrstuvwxyz";/// a..z
const char[26] uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";/// A..Z
const char[52] letters   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			               "abcdefghijklmnopqrstuvwxyz";/// A..Za..z
const char[6] whitespace = " \t\v\r\n\f";			    /// ASCII whitespace

const dchar LS = '\u2028';	/// UTF line separator
const dchar PS = '\u2029';	/// UTF paragraph separator

/// Newline sequence for this system
version (Windows)
    const char[2] newline = "\r\n";
else version (linux)
    const char[2] newline = "\n";

/**********************************
 * Compare two strings. cmp is case sensitive, icmp is case insensitive.
 * Returns:
 *	<table border=1 cellpadding=4 cellspacing=0>
 *	<tr> <td> < 0	<td> s1 < s2
 *	<tr> <td> = 0	<td> s1 == s2
 *	<tr> <td> > 0	<td> s1 > s2
 *	</table>
 */

int cmp(char[] s1, char[] s2)
{
    auto len = s1.length;
    int result;

    //printf("cmp('%.*s', '%.*s')\n", s1, s2);
    if (s2.length < len)
	len = s2.length;
    result = memcmp(s1, s2, len);
    if (result == 0)
	result = cast(int)s1.length - cast(int)s2.length;
    return result;
}

/*********************************
 * ditto
 */

int icmp(char[] s1, char[] s2)
{
    auto len = s1.length;
    int result;

    if (s2.length < len)
	len = s2.length;
    version (Win32)
    {
	result = memicmp(s1, s2, len);
    }
    version (linux)
    {
	for (size_t i = 0; i < len; i++)
	{
	    if (s1[i] != s2[i])
	    {
		char c1 = s1[i];
		char c2 = s2[i];

		if (c1 >= 'A' && c1 <= 'Z')
		    c1 += cast(int)'a' - cast(int)'A';
		if (c2 >= 'A' && c2 <= 'Z')
		    c2 += cast(int)'a' - cast(int)'A';
		result = cast(int)c1 - cast(int)c2;
		if (result)
		    break;
	    }
	}
    }
    if (result == 0)
	result = cast(int)s1.length - cast(int)s2.length;
    return result;
}

unittest
{
    int result;

    debug(string) printf("string.cmp.unittest\n");
    result = cmp("abc", "abc");
    assert(result == 0);
    result = cmp(null, null);
    assert(result == 0);
    result = cmp("", "");
    assert(result == 0);
    result = cmp("abc", "abcd");
    assert(result < 0);
    result = cmp("abcd", "abc");
    assert(result > 0);
    result = cmp("abc", "abd");
    assert(result < 0);
    result = cmp("bbc", "abc");
    assert(result > 0);
}

/*********************************
 * Convert array of chars s[] to a C-style 0 terminated string.
 */

char* toStringz(char[] s)
    in
    {
    }
    out (result)
    {
	if (result)
	{   assert(strlen(result) == s.length);
	    assert(memcmp(result, s, s.length) == 0);
	}
    }
    body
    {
	char[] copy;

	if (s.length == 0)
	    return "";

	/+ Unfortunately, this isn't reliable.
	   We could make this work if string literals are put
	   in read-only memory and we test if s[] is pointing into
	   that.

	    /* Peek past end of s[], if it's 0, no conversion necessary.
	     * Note that the compiler will put a 0 past the end of static
	     * strings, and the storage allocator will put a 0 past the end
	     * of newly allocated char[]'s.
	     */
	    char* p = &s[0] + s.length;
	    if (*p == 0)
		return s;
	+/

	// Need to make a copy
	copy = new char[s.length + 1];
	copy[0..s.length] = s;
	copy[s.length] = 0;
	return copy;
    }

unittest
{
    debug(string) printf("string.toStringz.unittest\n");

    char* p = toStringz("foo");
    assert(strlen(p) == 3);
    char foo[] = "abbzxyzzy";
    p = toStringz(foo[3..5]);
    assert(strlen(p) == 2);

    char[] test = "";
    p = toStringz(test);
    assert(*p == 0);
}

/*****************************
 * Return a _string that is string[] with slice[] replaced by replacement[].
 */

char[] replaceSlice(char[] string, char[] slice, char[] replacement)
in
{
    // Verify that slice[] really is a slice of string[]
    int so = cast(char*)slice - cast(char*)string;
    assert(so >= 0);
    //printf("string.length = %d, so = %d, slice.length = %d\n", string.length, so, slice.length);
    assert(string.length >= so + slice.length);
}
body
{
    char[] result;
    int so = cast(char*)slice - cast(char*)string;

    result.length = string.length - slice.length + replacement.length;

    result[0 .. so] = string[0 .. so];
    result[so .. so + replacement.length] = replacement;
    result[so + replacement.length .. result.length] = string[so + slice.length .. string.length];

    return result;
}

unittest
{
    debug(string) printf("string.replaceSlice.unittest\n");

    char[] string = "hello";
    char[] slice = string[2 .. 4];

    char[] r = replaceSlice(string, slice, "bar");
    int i;
    i = cmp(r, "hebaro");
    assert(i == 0);
}

/***********************************************
 * Convert to char[].
 */

char[] toString(bool b)
{
    return b ? "true" : "false";
}

/// ditto
char[] toString(char c)
{
    char[] result = new char[2];
    result[0] = c;
    result[1] = 0;
    return result[0 .. 1];
}

unittest
{
    debug(string) printf("string.toString(char).unittest\n");

    char[] s = "foo";
    char[] s2;
    foreach (char c; s)
    {
	s2 ~= toString(c);
    }
    //printf("%.*s", s2);
    assert(s2 == "foo");
}

char[] toString(ubyte ub)  { return toString(cast(uint) ub); } /// ditto
char[] toString(ushort us) { return toString(cast(uint) us); } /// ditto

/// ditto
char[] toString(uint u)
{   char[uint.sizeof * 3] buffer = void;
    int ndigits;
    char c;
    char[] result;

    ndigits = 0;
    if (u < 10)
	// Avoid storage allocation for simple stuff
	result = digits[u .. u + 1];
    else
    {
	while (u)
	{
	    c = (u % 10) + '0';
	    u /= 10;
	    ndigits++;
	    buffer[buffer.length - ndigits] = c;
	}
	result = new char[ndigits];
	result[] = buffer[buffer.length - ndigits .. buffer.length];
    }
    return result;
}

unittest
{
    debug(string) printf("string.toString(uint).unittest\n");

    char[] r;
    int i;

    r = toString(0u);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9u);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123u);
    i = cmp(r, "123");
    assert(i == 0);
}

/// ditto
char[] toString(ulong u)
{   char[ulong.sizeof * 3] buffer;
    int ndigits;
    char c;
    char[] result;

    if (u < 0x1_0000_0000)
	return toString(cast(uint)u);
    ndigits = 0;
    while (u)
    {
	c = (u % 10) + '0';
	u /= 10;
	ndigits++;
	buffer[buffer.length - ndigits] = c;
    }
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(ulong).unittest\n");

    char[] r;
    int i;

    r = toString(0uL);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9uL);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123uL);
    i = cmp(r, "123");
    assert(i == 0);
}

char[] toString(byte b)  { return toString(cast(int) b); } /// ditto
char[] toString(short s) { return toString(cast(int) s); } /// ditto

/// ditto
char[] toString(int i)
{   char[1 + int.sizeof * 3] buffer;
    char c;
    char[] result;

    if (i >= 0)
	return toString(cast(uint)i);

    uint u = -i;
    int ndigits = 1;
    while (u)
    {
	c = (u % 10) + '0';
	u /= 10;
	buffer[buffer.length - ndigits] = c;
	ndigits++;
    }
    buffer[buffer.length - ndigits] = '-';
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(int).unittest\n");

    char[] r;
    int i;

    r = toString(0);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123);
    i = cmp(r, "123");
    assert(i == 0);

    r = toString(-0);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(-9);
    i = cmp(r, "-9");
    assert(i == 0);

    r = toString(-123);
    i = cmp(r, "-123");
    assert(i == 0);
}

/// ditto
char[] toString(long i)
{   char[1 + long.sizeof * 3] buffer;
    char c;
    char[] result;

    if (i >= 0)
	return toString(cast(ulong)i);
    if (cast(int)i == i)
	return toString(cast(int)i);

    ulong u = -i;
    int ndigits = 1;
    while (u)
    {
	c = (u % 10) + '0';
	u /= 10;
	buffer[buffer.length - ndigits] = c;
	ndigits++;
    }
    buffer[buffer.length - ndigits] = '-';
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(long).unittest\n");

    char[] r;
    int i;

    r = toString(0L);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9L);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123L);
    i = cmp(r, "123");
    assert(i == 0);

    r = toString(-0L);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(-9L);
    i = cmp(r, "-9");
    assert(i == 0);

    r = toString(-123L);
    i = cmp(r, "-123");
    assert(i == 0);
}

/// ditto
char[] toString(float f) { return toString(cast(double) f); }

/// ditto
char[] toString(double d)
{
    char[20] buffer;

    sprintf(buffer, "%g", d);
    return toString(buffer).dup;
}

/// ditto
char[] toString(real r)
{
    char[20] buffer;

    sprintf(buffer, "%Lg", r);
    return toString(buffer).dup;
}

/// ditto
char[] toString(ifloat f) { return toString(cast(idouble) f); }

/// ditto
char[] toString(idouble d)
{
    char[21] buffer;

    sprintf(buffer, "%gi", d);
    return toString(buffer).dup;
}

/// ditto
char[] toString(ireal r)
{
    char[21] buffer;

    sprintf(buffer, "%Lgi", r);
    return toString(buffer).dup;
}

/// ditto
char[] toString(cfloat f) { return toString(cast(cdouble) f); }

/// ditto
char[] toString(cdouble d)
{
    char[20 + 1 + 20 + 1] buffer;

    sprintf(buffer, "%g+%gi", d.re, d.im);
    return toString(buffer).dup;
}

/// ditto
char[] toString(creal r)
{
    char[20 + 1 + 20 + 1] buffer;

    sprintf(buffer, "%Lg+%Lgi", r.re, r.im);
    return toString(buffer).dup;
}


/******************************************
 * Convert value to string in _radix radix.
 *
 * radix must be a value from 2 to 36.
 * value is treated as a signed value only if radix is 10.
 * The characters A through Z are used to represent values 10 through 36.
 */
char[] toString(long value, uint radix)
in
{
    assert(radix >= 2 && radix <= 36);
}
body
{
    if (radix == 10)
	return toString(value);		// handle signed cases only for radix 10
    return toString(cast(ulong)value, radix);
}

/// ditto
char[] toString(ulong value, uint radix)
in
{
    assert(radix >= 2 && radix <= 36);
}
body
{
    char[value.sizeof * 8] buffer;
    uint i = buffer.length;

    if (value < radix && value < hexdigits.length)
	return hexdigits[value .. value + 1];

    do
    {	ubyte c;

	c = value % radix;
	value = value / radix;
	i--;
	buffer[i] = (c < 10) ? c + '0' : c + 'A' - 10;
    } while (value);
    return buffer[i .. length].dup;
}

unittest
{
    debug(string) printf("string.toString(ulong, uint).unittest\n");

    char[] r;
    int i;

    r = toString(-10L, 10u);
    assert(r == "-10");

    r = toString(15L, 2u);
    //writefln("r = '%s'", r);
    assert(r == "1111");

    r = toString(1L, 2u);
    //writefln("r = '%s'", r);
    assert(r == "1");

    r = toString(0x1234AFL, 16u);
    //writefln("r = '%s'", r);
    assert(r == "1234AF");
}

/*************************************************
 * Convert C-style 0 terminated string s to char[] string.
 */

char[] toString(char *s)
{
    return s ? s[0 .. strlen(s)] : cast(char[])null;
}

unittest
{
    debug(string) printf("string.toString(char*).unittest\n");

    char[] r;
    int i;

    r = toString(null);
    i = cmp(r, "");
    assert(i == 0);

    r = toString("foo\0");
    i = cmp(r, "foo");
    assert(i == 0);
}