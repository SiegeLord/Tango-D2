
module rt.compiler.dmd.typeinfo.ti_Along;

private import tango.stdc.string : memcmp;
private import rt.compiler.util.hash;

// long[]

class TypeInfo_Al : TypeInfo_Array
{
    override char[] toString() { return "long[]"; }

    override hash_t getHash(in void* p)
    {   long[] s = *cast(long[]*)p;
        size_t len = s.length;
        auto str = s.ptr;
        return rt_hash_str(str,len*long.sizeof,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        long[] s1 = *cast(long[]*)p1;
        long[] s2 = *cast(long[]*)p2;

        return s1.length == s2.length &&
               memcmp(cast(void *)s1, cast(void *)s2, s1.length * long.sizeof) == 0;
    }

    override int compare(in void* p1, in void* p2)
    {
        long[] s1 = *cast(long[]*)p1;
        long[] s2 = *cast(long[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            if (s1[u] < s2[u])
                return -1;
            else if (s1[u] > s2[u])
                return 1;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    override size_t tsize()
    {
        return (long[]).sizeof;
    }

    override uint flags()
    {
        return 1;
    }

    override TypeInfo next()
    {
        return typeid(long);
    }
}


// ulong[]

class TypeInfo_Am : TypeInfo_Al
{
    override char[] toString() { return "ulong[]"; }

    override int compare(in void* p1, in void* p2)
    {
        ulong[] s1 = *cast(ulong[]*)p1;
        ulong[] s2 = *cast(ulong[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            if (s1[u] < s2[u])
                return -1;
            else if (s1[u] > s2[u])
                return 1;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    override TypeInfo next()
    {
        return typeid(ulong);
    }
}
