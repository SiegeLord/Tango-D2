
// cfloat

module rt.compiler.dmd.typeinfo.ti_cfloat;
private import rt.compiler.util.hash;

class TypeInfo_q : TypeInfo
{
    override char[] toString() { return "cfloat"; }

    override hash_t getHash(in void* p)
    {
        return rt_hash_str(p,cfloat.sizeof,0);
    }

    static equals_t _equals(cfloat f1, cfloat f2)
    {
        return f1 == f2;
    }

    static int _compare(cfloat f1, cfloat f2)
    {   int result;

        if (f1.re < f2.re)
            result = -1;
        else if (f1.re > f2.re)
            result = 1;
        else if (f1.im < f2.im)
            result = -1;
        else if (f1.im > f2.im)
            result = 1;
        else
            result = 0;
        return result;
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        return _equals(*cast(cfloat *)p1, *cast(cfloat *)p2);
    }

    override int compare(in void* p1, in void* p2)
    {
        return _compare(*cast(cfloat *)p1, *cast(cfloat *)p2);
    }

    override size_t tsize()
    {
        return cfloat.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        cfloat t;

        t = *cast(cfloat *)p1;
        *cast(cfloat *)p1 = *cast(cfloat *)p2;
        *cast(cfloat *)p2 = t;
    }

    override void[] init()
    {   static cfloat r;

        return (cast(cfloat *)&r)[0 .. 1];
    }
}
