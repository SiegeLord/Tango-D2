/***************************
 * D programming language http://www.digitalmars.com/d/
 * Runtime support for byte array operations.
 * Based on code originally written by Burton Radons.
 * Placed in public domain.
 */

/* Contains SSE2 and MMX versions of certain operations for wchar, short,
 * and ushort ('u', 's' and 't' suffixes).
 */

module rt.compiler.gdc.rt.arrayshort;

private import CPUid = rt.compiler.util.cpuid;

debug(UnitTest)
{
    private extern(C) int printf(char*,...);
    /* This is so unit tests will test every CPU variant
     */
    int cpuid;
    const int CPUID_MAX = 4;
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
    alias CPUid.sse2 sse2;
}

//version = log;

bool disjoint(T)(T[] a, T[] b)
{
    return (a.ptr + a.length <= b.ptr || b.ptr + b.length <= a.ptr);
}

alias short T;

extern (C):

/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] + value
 */

T[] _arraySliceExpAddSliceAssign_u(T[] a, T value, T[] b)
{
    return _arraySliceExpAddSliceAssign_s(a, value, b);
}

T[] _arraySliceExpAddSliceAssign_t(T[] a, T value, T[] b)
{
    return _arraySliceExpAddSliceAssign_s(a, value, b);
}

T[] _arraySliceExpAddSliceAssign_s(T[] a, T value, T[] b)
in
{
    assert(a.length == b.length);
    assert(disjoint(a, b));
}
body
{
    //printf("_arraySliceExpAddSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 3343% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= (l << 16);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
        }
        else
        // MMX version is 3343% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM1, [EAX+8];
                add EAX, 16;
                paddw MM0, MM2;
                paddw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ + value);

    return a;
}

unittest
{
    printf("_arraySliceExpAddSliceAssign_s unittest\n");

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

            c[] = a[] + 6;

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] + 6))
                {
                    printf("[%d]: %d != %d + 6\n", i, c[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] + c[]
 */

T[] _arraySliceSliceAddSliceAssign_u(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceAddSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceAddSliceAssign_t(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceAddSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceAddSliceAssign_s(T[] a, T[] c, T[] b)
in
{
        assert(a.length == b.length && b.length == c.length);
        assert(disjoint(a, b));
        assert(disjoint(a, c));
        assert(disjoint(b, c));
}
body
{
    //printf("_arraySliceSliceAddSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;
    auto cptr = c.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 3777% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr | cast(uint) cptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    movdqu XMM2, [ECX];
                    movdqu XMM3, [ECX+16];
                    add ECX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    movdqa XMM2, [ECX];
                    movdqa XMM3, [ECX+16];
                    add ECX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
                }
            }
        }
        else
        // MMX version is 2068% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                mov ECX, cptr;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM1, [EAX+8];
                add EAX, 16;
                movq MM2, [ECX];
                movq MM3, [ECX+8];
                add ECX, 16;
                paddw MM0, MM2;
                paddw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
                mov cptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ + *cptr++);

    return a;
}

unittest
{
    printf("_arraySliceSliceAddSliceAssign_s unittest\n");

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
                    printf("[%d]: %d != %d + %d\n", i, c[i], a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] += value
 */

T[] _arrayExpSliceAddass_u(T[] a, T value)
{
    return _arrayExpSliceAddass_s(a, value);
}

T[] _arrayExpSliceAddass_t(T[] a, T value)
{
    return _arrayExpSliceAddass_s(a, value);
}

T[] _arrayExpSliceAddass_s(T[] a, T value)
{
    //printf("_arrayExpSliceAddass_s(a.length = %d, value = %Lg)\n", a.length, cast(real)value);
    auto aptr = a.ptr;
    auto aend = aptr + a.length;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 832% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= (l << 16);

            if (((cast(uint) aptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM1, [ESI+16];
                    add ESI, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2u;

                    mov aptr, ESI;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM1, [ESI+16];
                    add ESI, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2a;

                    mov aptr, ESI;
                }
            }
        }
        else
        // MMX version is 826% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                movq MM0, [ESI];
                movq MM1, [ESI+8];
                add ESI, 16;
                paddw MM0, MM2;
                paddw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
            }
        }
    }

    while (aptr < aend)
        *aptr++ += value;

    return a;
}

unittest
{
    printf("_arrayExpSliceAddass_s unittest\n");

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

            a[] = c[];
            a[] += 6;

            for (int i = 0; i < dim; i++)
            {
                if (a[i] != cast(T)(c[i] + 6))
                {
                    printf("[%d]: %d != %d + 6\n", i, a[i], c[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] += b[]
 */

T[] _arraySliceSliceAddass_u(T[] a, T[] b)
{
    return _arraySliceSliceAddass_s(a, b);
}

T[] _arraySliceSliceAddass_t(T[] a, T[] b)
{
    return _arraySliceSliceAddass_s(a, b);
}

T[] _arraySliceSliceAddass_s(T[] a, T[] b)
in
{
    assert (a.length == b.length);
    assert (disjoint(a, b));
}
body
{
    //printf("_arraySliceSliceAddass_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 2085% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM1, [ESI+16];
                    add ESI, 32;
                    movdqu XMM2, [ECX];
                    movdqu XMM3, [ECX+16];
                    add ECX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, ECX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM1, [ESI+16];
                    add ESI, 32;
                    movdqa XMM2, [ECX];
                    movdqa XMM3, [ECX+16];
                    add ECX, 32;
                    paddw XMM0, XMM2;
                    paddw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, ECX;
                }
            }
        }
        else
        // MMX version is 1022% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov ECX, bptr;

                align 4;
            start:
                movq MM0, [ESI];
                movq MM1, [ESI+8];
                add ESI, 16;
                movq MM2, [ECX];
                movq MM3, [ECX+8];
                add ECX, 16;
                paddw MM0, MM2;
                paddw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb start;

                emms;
                mov aptr, ESI;
                mov bptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ += *bptr++;

    return a;
}

unittest
{
    printf("_arraySliceSliceAddass_s unittest\n");

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

            b[] = c[];
            c[] += a[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(b[i] + a[i]))
                {
                    printf("[%d]: %d != %d + %d\n", i, c[i], b[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] - value
 */

T[] _arraySliceExpMinSliceAssign_u(T[] a, T value, T[] b)
{
    return _arraySliceExpMinSliceAssign_s(a, value, b);
}

T[] _arraySliceExpMinSliceAssign_t(T[] a, T value, T[] b)
{
    return _arraySliceExpMinSliceAssign_s(a, value, b);
}

T[] _arraySliceExpMinSliceAssign_s(T[] a, T value, T[] b)
in
{
    assert(a.length == b.length);
    assert(disjoint(a, b));
}
body
{
    //printf("_arraySliceExpMinSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 3695% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= (l << 16);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
        }
        else
        // MMX version is 3049% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM1, [EAX+8];
                add EAX, 16;
                psubw MM0, MM2;
                psubw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ - value);

    return a;
}

unittest
{
    printf("_arraySliceExpMinSliceAssign_s unittest\n");

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

            c[] = a[] - 6;

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] - 6))
                {
                    printf("[%d]: %d != %d - 6\n", i, c[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = value - b[]
 */

T[] _arrayExpSliceMinSliceAssign_u(T[] a, T[] b, T value)
{
    return _arrayExpSliceMinSliceAssign_s(a, b, value);
}

T[] _arrayExpSliceMinSliceAssign_t(T[] a, T[] b, T value)
{
    return _arrayExpSliceMinSliceAssign_s(a, b, value);
}

T[] _arrayExpSliceMinSliceAssign_s(T[] a, T[] b, T value)
in
{
    assert(a.length == b.length);
    assert(disjoint(a, b));
}
body
{
    //printf("_arrayExpSliceMinSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 4995% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= (l << 16);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;

                    align 4;
                startaddsse2u:
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;
                    movd XMM3, l;
                    pshufd XMM3, XMM3, 0;
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    psubw XMM2, XMM0;
                    psubw XMM3, XMM1;
                    movdqu [ESI   -32], XMM2;
                    movdqu [ESI+16-32], XMM3;
                    cmp ESI, EDI;
                    jb startaddsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;

                    align 4;
                startaddsse2a:
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;
                    movd XMM3, l;
                    pshufd XMM3, XMM3, 0;
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    psubw XMM2, XMM0;
                    psubw XMM3, XMM1;
                    movdqa [ESI   -32], XMM2;
                    movdqa [ESI+16-32], XMM3;
                    cmp ESI, EDI;
                    jb startaddsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
        }
        else
        // MMX version is 4562% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                movd MM4, l;
                pshufw MM4, MM4, 0;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM2, [EAX];
                movq MM3, [EAX+8];
                movq MM0, MM4;
                movq MM1, MM4;
                add EAX, 16;
                psubw MM0, MM2;
                psubw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(value - *bptr++);

    return a;
}

unittest
{
    printf("_arrayExpSliceMinSliceAssign_s unittest\n");

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

            c[] = 6 - a[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(6 - a[i]))
                {
                    printf("[%d]: %d != 6 - %d\n", i, c[i], a[i]);
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

T[] _arraySliceSliceMinSliceAssign_u(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceMinSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceMinSliceAssign_t(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceMinSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceMinSliceAssign_s(T[] a, T[] c, T[] b)
in
{
        assert(a.length == b.length && b.length == c.length);
        assert(disjoint(a, b));
        assert(disjoint(a, c));
        assert(disjoint(b, c));
}
body
{
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;
    auto cptr = c.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 4129% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr | cast(uint) cptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    movdqu XMM2, [ECX];
                    movdqu XMM3, [ECX+16];
                    add ECX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    movdqa XMM2, [ECX];
                    movdqa XMM3, [ECX+16];
                    add ECX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
                }
            }
        }
        else
        // MMX version is 2018% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                mov ECX, cptr;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM1, [EAX+8];
                add EAX, 16;
                movq MM2, [ECX];
                movq MM3, [ECX+8];
                add ECX, 16;
                psubw MM0, MM2;
                psubw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
                mov cptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ - *cptr++);

    return a;
}

unittest
{
    printf("_arraySliceSliceMinSliceAssign_s unittest\n");

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
                    printf("[%d]: %d != %d - %d\n", i, c[i], a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] -= value
 */

T[] _arrayExpSliceMinass_u(T[] a, T value)
{
    return _arrayExpSliceMinass_s(a, value);
}

T[] _arrayExpSliceMinass_t(T[] a, T value)
{
    return _arrayExpSliceMinass_s(a, value);
}

T[] _arrayExpSliceMinass_s(T[] a, T value)
{
    //printf("_arrayExpSliceMinass_s(a.length = %d, value = %Lg)\n", a.length, cast(real)value);
    auto aptr = a.ptr;
    auto aend = aptr + a.length;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 835% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= (l << 16);

            if (((cast(uint) aptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM1, [ESI+16];
                    add ESI, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2u;

                    mov aptr, ESI;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startaddsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM1, [ESI+16];
                    add ESI, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startaddsse2a;

                    mov aptr, ESI;
                }
            }
        }
        else
        // MMX version is 835% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                movq MM0, [ESI];
                movq MM1, [ESI+8];
                add ESI, 16;
                psubw MM0, MM2;
                psubw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
            }
        }
    }

    while (aptr < aend)
        *aptr++ -= value;

    return a;
}

unittest
{
    printf("_arrayExpSliceMinass_s unittest\n");

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

            a[] = c[];
            a[] -= 6;

            for (int i = 0; i < dim; i++)
            {
                if (a[i] != cast(T)(c[i] - 6))
                {
                    printf("[%d]: %d != %d - 6\n", i, a[i], c[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] -= b[]
 */

T[] _arraySliceSliceMinass_u(T[] a, T[] b)
{
    return _arraySliceSliceMinass_s(a, b);
}

T[] _arraySliceSliceMinass_t(T[] a, T[] b)
{
    return _arraySliceSliceMinass_s(a, b);
}

T[] _arraySliceSliceMinass_s(T[] a, T[] b)
in
{
    assert (a.length == b.length);
    assert (disjoint(a, b));
}
body
{
    //printf("_arraySliceSliceMinass_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 2121% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm // unaligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM1, [ESI+16];
                    add ESI, 32;
                    movdqu XMM2, [ECX];
                    movdqu XMM3, [ECX+16];
                    add ECX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, ECX;
                }
            }
            else
            {
                asm // aligned case
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM1, [ESI+16];
                    add ESI, 32;
                    movdqa XMM2, [ECX];
                    movdqa XMM3, [ECX+16];
                    add ECX, 32;
                    psubw XMM0, XMM2;
                    psubw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, ECX;
                }
            }
        }
        else
        // MMX version is 1116% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov ECX, bptr;

                align 4;
            start:
                movq MM0, [ESI];
                movq MM1, [ESI+8];
                add ESI, 16;
                movq MM2, [ECX];
                movq MM3, [ECX+8];
                add ECX, 16;
                psubw MM0, MM2;
                psubw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb start;

                emms;
                mov aptr, ESI;
                mov bptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ -= *bptr++;

    return a;
}

unittest
{
    printf("_arraySliceSliceMinass_s unittest\n");

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

            b[] = c[];
            c[] -= a[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(b[i] - a[i]))
                {
                    printf("[%d]: %d != %d - %d\n", i, c[i], b[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] * value
 */

T[] _arraySliceExpMulSliceAssign_u(T[] a, T value, T[] b)
{
    return _arraySliceExpMulSliceAssign_s(a, value, b);
}

T[] _arraySliceExpMulSliceAssign_t(T[] a, T value, T[] b)
{
    return _arraySliceExpMulSliceAssign_s(a, value, b);
}

T[] _arraySliceExpMulSliceAssign_s(T[] a, T value, T[] b)
in
{
    assert(a.length == b.length);
    assert(disjoint(a, b));
}
body
{
    //printf("_arraySliceExpMulSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 3733% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= l << 16;

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM1, [EAX+16];
                    add EAX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
            else
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM1, [EAX+16];
                    add EAX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                }
            }
        }
        else
        // MMX version is 3733% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM1, [EAX+8];
                add EAX, 16;
                pmullw MM0, MM2;
                pmullw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ * value);

    return a;
}

unittest
{
    printf("_arraySliceExpMulSliceAssign_s unittest\n");

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

            c[] = a[] * 6;

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] * 6))
                {
                    printf("[%d]: %d != %d * 6\n", i, c[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] = b[] * c[]
 */

T[] _arraySliceSliceMulSliceAssign_u(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceMulSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceMulSliceAssign_t(T[] a, T[] c, T[] b)
{
    return _arraySliceSliceMulSliceAssign_s(a, c, b);
}

T[] _arraySliceSliceMulSliceAssign_s(T[] a, T[] c, T[] b)
in
{
        assert(a.length == b.length && b.length == c.length);
        assert(disjoint(a, b));
        assert(disjoint(a, c));
        assert(disjoint(b, c));
}
body
{
    //printf("_arraySliceSliceMulSliceAssign_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;
    auto cptr = c.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 2515% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr | cast(uint) cptr) & 15) != 0)
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2u:
                    add ESI, 32;
                    movdqu XMM0, [EAX];
                    movdqu XMM2, [ECX];
                    movdqu XMM1, [EAX+16];
                    movdqu XMM3, [ECX+16];
                    add EAX, 32;
                    add ECX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
                }
            }
            else
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov EAX, bptr;
                    mov ECX, cptr;

                    align 4;
                startsse2a:
                    add ESI, 32;
                    movdqa XMM0, [EAX];
                    movdqa XMM2, [ECX];
                    movdqa XMM1, [EAX+16];
                    movdqa XMM3, [ECX+16];
                    add EAX, 32;
                    add ECX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, EAX;
                    mov cptr, ECX;
               }
            }
        }
        else
        // MMX version is 2515% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov EAX, bptr;
                mov ECX, cptr;

                align 4;
            startmmx:
                add ESI, 16;
                movq MM0, [EAX];
                movq MM2, [ECX];
                movq MM1, [EAX+8];
                movq MM3, [ECX+8];
                add EAX, 16;
                add ECX, 16;
                pmullw MM0, MM2;
                pmullw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, EAX;
                mov cptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ = cast(T)(*bptr++ * *cptr++);

    return a;
}

unittest
{
    printf("_arraySliceSliceMulSliceAssign_s unittest\n");

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

            c[] = a[] * b[];

            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] * b[i]))
                {
                    printf("[%d]: %d != %d * %d\n", i, c[i], a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] *= value
 */

T[] _arrayExpSliceMulass_u(T[] a, T value)
{
    return _arrayExpSliceMulass_s(a, value);
}

T[] _arrayExpSliceMulass_t(T[] a, T value)
{
    return _arrayExpSliceMulass_s(a, value);
}

T[] _arrayExpSliceMulass_s(T[] a, T value)
{
    //printf("_arrayExpSliceMulass_s(a.length = %d, value = %Lg)\n", a.length, cast(real)value);
    auto aptr = a.ptr;
    auto aend = aptr + a.length;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 2044% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            uint l = cast(ushort) value;
            l |= l << 16;

            if (((cast(uint) aptr) & 15) != 0)
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM1, [ESI+16];
                    add ESI, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM2;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                }
            }
            else
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    movd XMM2, l;
                    pshufd XMM2, XMM2, 0;

                    align 4;
                startsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM1, [ESI+16];
                    add ESI, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM2;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                }
            }
        }
        else
        // MMX version is 2056% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            uint l = cast(ushort) value;

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                movd MM2, l;
                pshufw MM2, MM2, 0;

                align 4;
            startmmx:
                movq MM0, [ESI];
                movq MM1, [ESI+8];
                add ESI, 16;
                pmullw MM0, MM2;
                pmullw MM1, MM2;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
            }
        }
    }

    while (aptr < aend)
        *aptr++ *= value;

    return a;
}

unittest
{
    printf("_arrayExpSliceMulass_s unittest\n");

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

            b[] = a[];
            a[] *= 6;

            for (int i = 0; i < dim; i++)
            {
                if (a[i] != cast(T)(b[i] * 6))
                {
                    printf("[%d]: %d != %d * 6\n", i, a[i], b[i]);
                    assert(0);
                }
            }
        }
    }
}


/* ======================================================================== */

/***********************
 * Computes:
 *      a[] *= b[]
 */

T[] _arraySliceSliceMulass_u(T[] a, T[] b)
{
    return _arraySliceSliceMulass_s(a, b);
}

T[] _arraySliceSliceMulass_t(T[] a, T[] b)
{
    return _arraySliceSliceMulass_s(a, b);
}

T[] _arraySliceSliceMulass_s(T[] a, T[] b)
in
{
    assert (a.length == b.length);
    assert (disjoint(a, b));
}
body
{
    //printf("_arraySliceSliceMulass_s()\n");
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86)
    {
        // SSE2 aligned version is 2519% faster
        if (sse2() && a.length >= 16)
        {
            auto n = aptr + (a.length & ~15);

            if (((cast(uint) aptr | cast(uint) bptr) & 15) != 0)
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2u:
                    movdqu XMM0, [ESI];
                    movdqu XMM2, [ECX];
                    movdqu XMM1, [ESI+16];
                    movdqu XMM3, [ECX+16];
                    add ESI, 32;
                    add ECX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM3;
                    movdqu [ESI   -32], XMM0;
                    movdqu [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2u;

                    mov aptr, ESI;
                    mov bptr, ECX;
                }
            }
            else
            {
                asm
                {
                    mov ESI, aptr;
                    mov EDI, n;
                    mov ECX, bptr;

                    align 4;
                startsse2a:
                    movdqa XMM0, [ESI];
                    movdqa XMM2, [ECX];
                    movdqa XMM1, [ESI+16];
                    movdqa XMM3, [ECX+16];
                    add ESI, 32;
                    add ECX, 32;
                    pmullw XMM0, XMM2;
                    pmullw XMM1, XMM3;
                    movdqa [ESI   -32], XMM0;
                    movdqa [ESI+16-32], XMM1;
                    cmp ESI, EDI;
                    jb startsse2a;

                    mov aptr, ESI;
                    mov bptr, ECX;
               }
            }
        }
        else
        // MMX version is 1712% faster
        if (mmx() && a.length >= 8)
        {
            auto n = aptr + (a.length & ~7);

            asm
            {
                mov ESI, aptr;
                mov EDI, n;
                mov ECX, bptr;

                align 4;
            startmmx:
                movq MM0, [ESI];
                movq MM2, [ECX];
                movq MM1, [ESI+8];
                movq MM3, [ECX+8];
                add ESI, 16;
                add ECX, 16;
                pmullw MM0, MM2;
                pmullw MM1, MM3;
                movq [ESI  -16], MM0;
                movq [ESI+8-16], MM1;
                cmp ESI, EDI;
                jb startmmx;

                emms;
                mov aptr, ESI;
                mov bptr, ECX;
            }
        }
    }

    while (aptr < aend)
        *aptr++ *= *bptr++;

    return a;
}

unittest
{
    printf("_arraySliceSliceMulass_s unittest\n");

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

            b[] = a[];
            a[] *= c[];

            for (int i = 0; i < dim; i++)
            {
                if (a[i] != cast(T)(b[i] * c[i]))
                {
                    printf("[%d]: %d != %d * %d\n", i, a[i], b[i], c[i]);
                    assert(0);
                }
            }
        }
    }
}
