
module rt.compiler.dmd.typeinfo.ti_Ashort;

private import tango.stdc.string : memcmp;
private import rt.compiler.util.hash;

// short[]

class TypeInfo_As : TypeInfo_Array
{
    override char[] toString() { return "short[]"; }

    override hash_t getHash(in void* p)
    {   short[] s = *cast(short[]*)p;
        size_t len = s.length;
        short *str = s.ptr;
        return rt_hash_str(str,len*short.sizeof,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        short[] s1 = *cast(short[]*)p1;
        short[] s2 = *cast(short[]*)p2;

        return s1.length == s2.length &&
               memcmp(cast(void *)s1, cast(void *)s2, s1.length * short.sizeof) == 0;
    }

    override int compare(in void* p1, in void* p2)
    {
        short[] s1 = *cast(short[]*)p1;
        short[] s2 = *cast(short[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            int result = s1[u] - s2[u];
            if (result)
                return result;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    override size_t tsize()
    {
        return (short[]).sizeof;
    }

    override uint flags()
    {
        return 1;
    }

    override TypeInfo next()
    {
        return typeid(short);
    }
}


// ushort[]

class TypeInfo_At : TypeInfo_As
{
    override char[] toString() { return "ushort[]"; }

    override int compare(in void* p1, in void* p2)
    {
        ushort[] s1 = *cast(ushort[]*)p1;
        ushort[] s2 = *cast(ushort[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            int result = s1[u] - s2[u];
            if (result)
                return result;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    override TypeInfo next()
    {
        return typeid(ushort);
    }
}

// wchar[]

class TypeInfo_Au : TypeInfo_At
{
    override char[] toString() { return "wchar[]"; }

    // getHash should be overridden and call rt_hash_utf16 if one wants dependence for codepoints only
    override TypeInfo next()
    {
        return typeid(wchar);
    }
}
