
// dchar

module rt.compiler.dmd.typeinfo.ti_dchar;

class TypeInfo_w : TypeInfo
{
    override char[] toString() { return "dchar"; }

    override hash_t getHash(in void* p)
    {
        return cast(hash_t)*cast(dchar *)p;
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        return *cast(dchar *)p1 == *cast(dchar *)p2;
    }

    override int compare(in void* p1, in void* p2)
    {
        return *cast(dchar *)p1 - *cast(dchar *)p2;
    }

    override size_t tsize()
    {
        return dchar.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        dchar t;

        t = *cast(dchar *)p1;
        *cast(dchar *)p1 = *cast(dchar *)p2;
        *cast(dchar *)p2 = t;
    }

    override void[] init()
    {   static dchar c;

        return (cast(dchar *)&c)[0 .. 1];
    }
}
