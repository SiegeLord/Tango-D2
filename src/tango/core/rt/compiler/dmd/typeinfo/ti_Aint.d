
module rt.compiler.dmd.typeinfo.ti_Aint;

private import tango.stdc.string : memcmp;
private import rt.compiler.util.hash;

// int[]

class TypeInfo_Ai : TypeInfo_Array
{
    override char[] toString() { return "int[]"; }

    override hash_t getHash(in void* p)
    {   int[] s = *cast(int[]*)p;
        auto len = s.length;
        auto str = s.ptr;
        return rt_hash_str(str,len*int.sizeof,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        int[] s1 = *cast(int[]*)p1;
        int[] s2 = *cast(int[]*)p2;

        return s1.length == s2.length &&
               memcmp(cast(void *)s1, cast(void *)s2, s1.length * int.sizeof) == 0;
    }

    override int compare(in void* p1, in void* p2)
    {
        int[] s1 = *cast(int[]*)p1;
        int[] s2 = *cast(int[]*)p2;
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
        return (int[]).sizeof;
    }

    override uint flags()
    {
        return 1;
    }

    override TypeInfo next()
    {
        return typeid(int);
    }
}

unittest
{
    int[][] a = [[5,3,8,7], [2,5,3,8,7]];
    a.sort;
    assert(a == [[2,5,3,8,7], [5,3,8,7]]);

    a = [[5,3,8,7], [5,3,8]];
    a.sort;
    assert(a == [[5,3,8], [5,3,8,7]]);
}

// uint[]

class TypeInfo_Ak : TypeInfo_Ai
{
    override char[] toString() { return "uint[]"; }

    override int compare(in void* p1, in void* p2)
    {
        uint[] s1 = *cast(uint[]*)p1;
        uint[] s2 = *cast(uint[]*)p2;
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
        return typeid(uint);
    }
}

// dchar[]

class TypeInfo_Aw : TypeInfo_Ak
{
    override char[] toString() { return "dchar[]"; }

    override TypeInfo next()
    {
        return typeid(dchar);
    }
}
