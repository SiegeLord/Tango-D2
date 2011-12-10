
// delegate

module rt.compiler.gdc.typeinfo.ti_delegate;
private import rt.compiler.util.hash;

alias void delegate(int) dg;

class TypeInfo_D : TypeInfo
{
    override hash_t getHash(in void* p)
    {
        return rt_hash_block(cast(size_t *)p,2,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        return *cast(dg *)p1 == *cast(dg *)p2;
    }

    override size_t talign()
    {
        return dg.alignof;
    }

    override size_t tsize()
    {
        return dg.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        dg t;

        t = *cast(dg *)p1;
        *cast(dg *)p1 = *cast(dg *)p2;
        *cast(dg *)p2 = t;
    }

    override uint flags()
    {
        return 1;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        arg2 = typeid(void*);
        return 0;
    }
}
