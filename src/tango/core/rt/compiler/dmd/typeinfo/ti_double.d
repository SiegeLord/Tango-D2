
// double

module rt.compiler.dmd.typeinfo.ti_double;
private import rt.compiler.util.hash;

class TypeInfo_d : TypeInfo
{
    override char[] toString() { return "double"; }

    override hash_t getHash(in void* p)
    {
        return rt_hash_str(p,double.sizeof);
    }

    static equals_t _equals(double f1, double f2)
    {
        return f1 == f2 ||
                (f1 !<>= f1 && f2 !<>= f2);
    }

    static int _compare(double d1, double d2)
    {
        if (d1 !<>= d2)         // if either are NaN
        {
            if (d1 !<>= d1)
            {   if (d2 !<>= d2)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (d1 == d2) ? 0 : ((d1 < d2) ? -1 : 1);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        return _equals(*cast(double *)p1, *cast(double *)p2);
    }

    override int compare(in void* p1, in void* p2)
    {
        return _compare(*cast(double *)p1, *cast(double *)p2);
    }

    override size_t tsize()
    {
        return double.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        double t;

        t = *cast(double *)p1;
        *cast(double *)p1 = *cast(double *)p2;
        *cast(double *)p2 = t;
    }

    override void[] init()
    {   static double r;

        return (cast(double *)&r)[0 .. 1];
    }
}
