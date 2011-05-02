/***************************
 * D programming language http://www.digitalmars.com/d/
 * Runtime support for double array operations.
 * Placed in public domain.
 */

module rt.compiler.dmd.rt.arrayreal;

import CPUid = rt.compiler.util.cpuid;

debug(UnitTest)
{
    private extern(C) int printf(char*,...);
    /* This is so unit tests will test every CPU variant
     */
    int cpuid;
    const int CPUID_MAX = 1;
    bool mmx()      { return cpuid == 1 && CPUid.mmx(); }
    bool sse()      { return cpuid == 2 && CPUid.sse(); }
    bool sse2()     { return cpuid == 3 && CPUid.sse2(); }
    bool amd3dnow() { return cpuid == 4 && CPUid.amd3dnow(); }
}
else
{
    alias CPUid.mmx mmx;
    alias CPUid.sse sse;
    alias CPUid.sse2 sse2;
    alias CPUid.amd3dnow amd3dnow;
}

//version = log;

bool disjoint(T)(T[] a, T[] b)
{
    return (a.ptr + a.length <= b.ptr || b.ptr + b.length <= a.ptr);
}

alias real T;

extern (C):

/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] + c[]
 */

T[] _arraySliceSliceAddSliceAssign_r(T[] a, T[] c, T[] b)
in
{
        assert(a.length == b.length && b.length == c.length);
        assert(disjoint(a, b));
        assert(disjoint(a, c));
        assert(disjoint(b, c));
}
body
{
    for (int i = 0; i < a.length; i++)
        a[i] = b[i] + c[i];
    return a;
}

unittest
{
    printf("_arraySliceSliceAddSliceAssign_r unittest\n");
    for (cpuid = 0; cpuid < CPUID_MAX; cpuid++)
    {
        version (log) printf("    cpuid %d\n", cpuid);

        for (int j = 0; j < 2; j++)
        {
            const int dim = 67;
            T[] a = new T[dim + j];     // aligned on 16 byte boundary
            a = a[j .. dim + j];        // misalign for second iteration
            T[] b = new T[dim + j];
            b = b[j .. dim + j];
            T[] c = new T[dim + j];
            c = c[j .. dim + j];

            for (int i = 0; i < dim; i++)
            {   a[i] = cast(T)i;
                b[i] = cast(T)(i + 7);
                c[i] = cast(T)(i * 2);
            }

            c[] = a[] + b[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] + b[i]))
                {
                    printf("[%d]: %Lg != %Lg + %Lg\n", i, c[i], a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}

/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] - c[]
 */

T[] _arraySliceSliceMinSliceAssign_r(T[] a, T[] c, T[] b)
in
{
        assert(a.length == b.length && b.length == c.length);
        assert(disjoint(a, b));
        assert(disjoint(a, c));
        assert(disjoint(b, c));
}
body
{
    for (int i = 0; i < a.length; i++)
        a[i] = b[i] - c[i];
    return a;
}


unittest
{
    printf("_arraySliceSliceMinSliceAssign_r unittest\n");
    for (cpuid = 0; cpuid < CPUID_MAX; cpuid++)
    {
        version (log) printf("    cpuid %d\n", cpuid);

        for (int j = 0; j < 2; j++)
        {
            const int dim = 67;
            T[] a = new T[dim + j];     // aligned on 16 byte boundary
            a = a[j .. dim + j];        // misalign for second iteration
            T[] b = new T[dim + j];
            b = b[j .. dim + j];
            T[] c = new T[dim + j];
            c = c[j .. dim + j];

            for (int i = 0; i < dim; i++)
            {   a[i] = cast(T)i;
                b[i] = cast(T)(i + 7);
                c[i] = cast(T)(i * 2);
            }

            c[] = a[] - b[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] - b[i]))
                {
                    printf("[%d]: %Lg != %Lg - %Lg\n", i, c[i], a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}

/* ======================================================================== */

/***********************
 * Computes:
 *      a[] -= b[] * value
 */

T[] _arraySliceExpMulSliceMinass_r(T[] a, T value, T[] b)
{
    return _arraySliceExpMulSliceAddass_r(a, -value, b);
}

/***********************
 * Computes:
 *      a[] += b[] * value
 */

T[] _arraySliceExpMulSliceAddass_r(T[] a, T value, T[] b)
in
{
        assert(a.length == b.length);
        assert(disjoint(a, b));
}
body
{
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    // Handle remainder
    while (aptr < aend)
        *aptr++ += *bptr++ * value;

    return a;
}

unittest
{
    printf("_arraySliceExpMulSliceAddass_r unittest\n");

    cpuid = 1;
    {
        version (log) printf("    cpuid %d\n", cpuid);

        for (int j = 0; j < 1; j++)
        {
            const int dim = 67;
            T[] a = new T[dim + j];     // aligned on 16 byte boundary
            a = a[j .. dim + j];        // misalign for second iteration
            T[] b = new T[dim + j];
            b = b[j .. dim + j];
            T[] c = new T[dim + j];
            c = c[j .. dim + j];

            for (int i = 0; i < dim; i++)
            {   a[i] = cast(T)i;
                b[i] = cast(T)(i + 7);
                c[i] = cast(T)(i * 2);
            }

            b[] = c[];
            c[] += a[] * 6;

            for (int i = 0; i < dim; i++)
            {
                //printf("[%d]: %Lg ?= %Lg + %Lg * 6\n", i, c[i], b[i], a[i]);
                if (c[i] != cast(T)(b[i] + a[i] * 6))
                {
                    printf("[%d]: %Lg ?= %Lg + %Lg * 6\n", i, c[i], b[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}
