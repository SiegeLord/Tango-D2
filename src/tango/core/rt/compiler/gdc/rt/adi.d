//_ adi.d

/**
 * Part of the D programming language runtime library.
 * Dynamic array property support routines
 */

/*
 *  Copyright (C) 2000-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, April 2005
*/

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */
module rt.compiler.gdc.rt.adi;

//debug=adi;            // uncomment to turn on debugging printf's

private
{
    import tango.stdc.string;
    import tango.stdc.stdlib;
    import rt.compiler.util.utf;

    enum BlkAttr : uint
    {
        FINALIZE = 0b0000_0001,
        NO_SCAN  = 0b0000_0010,
        NO_MOVE  = 0b0000_0100,
        ALL_BITS = 0b1111_1111
    }

    extern (C) void*  gc_malloc( size_t sz, uint ba = 0, PointerMap bitMask = PointerMap.init);
    extern (C) void*  gc_calloc( size_t sz, uint ba = 0, PointerMap bitMask = PointerMap.init);
    extern (C) void  gc_free( void* p );
    extern (C) int printf(char*,...);
}


struct Array
{
    size_t  length;
    void*   ptr;
}

/**********************************************
 * Reverse array of chars.
 * Handled separately because embedded multibyte encodings should not be
 * reversed.
 */

extern (C) Array _adReverseChar(char[] a)
{
    bool hadErrors=false;
    if (a.length > 1)
    {
        char[6] tmp;
        char[6] tmplo;
        char* lo = a.ptr;
        char* hi = &a[length - 1];

        while (lo < hi)
        {   auto clo = *lo;
            auto chi = *hi;

            debug(adi) printf("lo = %d, hi = %d\n", lo, hi);
            if (clo <= 0x7F && chi <= 0x7F)
            {
                debug(adi) printf("\tascii\n");
                *lo = chi;
                *hi = clo;
                lo++;
                hi--;
                continue;
            }

            uint stridelo = UTF8stride[clo];
            if (stridelo>6) { // invalid UTF-8 0xFF
                stridelo=1;
                hadErrors=true; 
            }

            uint stridehi = 1;
            while ((chi & 0xC0) == 0x80 && hi >= lo)
            {
                chi = *--hi;
                stridehi++;
            }
            if (lo >= hi){
                if (lo>hi){
                    hadErrors=true;
                }
                break;
            }
            if (stridehi>6){
                hadErrors=true;
                stridehi=6;
            }

            debug(adi) printf("\tstridelo = %d, stridehi = %d\n", stridelo, stridehi);
            if (stridelo == stridehi)
            {
                memcpy(tmp.ptr, lo, stridelo);
                memcpy(lo, hi, stridelo);
                memcpy(hi, tmp.ptr, stridelo);
                lo += stridelo;
                hi--;
                continue;
            }

            /* Shift the whole array. This is woefully inefficient
             */
            memcpy(tmp.ptr, hi, stridehi);
            memcpy(tmplo.ptr, lo, stridelo);
            memmove(lo + stridehi, lo + stridelo , (hi - lo) - stridelo);
            memcpy(lo, tmp.ptr, stridehi);
            memcpy(hi + cast(int) stridehi - cast(int) stridelo, tmplo.ptr, stridelo);

            lo += stridehi;
            hi = hi - 1 + (cast(int) stridehi - cast(int) stridelo);
        }
    }
    if (hadErrors)
        throw new Exception("invalid UTF-8 sequence",__FILE__,__LINE__);
    return *cast(Array*)(&a);
}

unittest
{
    auto a = "abcd"c[];

    auto r = a.dup.reverse;
    //writefln(r);
    assert(r == "dcba");

    a = "a\u1235\u1234c";
    //writefln(a);
    r = a.dup.reverse;
    //writefln(r);
    assert(r == "c\u1234\u1235a");

    a = "ab\u1234c";
    //writefln(a);
    r = a.dup.reverse;
    //writefln(r);
    assert(r == "c\u1234ba");

    a = "\u3026\u2021\u3061\n";
    r = a.dup.reverse;
    assert(r == "\n\u3061\u2021\u3026");
}


/**********************************************
 * Reverse array of wchars.
 * Handled separately because embedded multiword encodings should not be
 * reversed.
 */

extern (C) Array _adReverseWchar(wchar[] a)
{
    bool hadErrors=false;
    if (a.length > 1)
    {
        wchar[2] tmp;
        wchar* lo = a.ptr;
        wchar* hi = &a[length - 1];

        while (lo < hi)
        {   auto clo = *lo;
            auto chi = *hi;

            if ((clo < 0xD800 || clo > 0xDFFF) &&
                (chi < 0xD800 || chi > 0xDFFF))
            {
                *lo = chi;
                *hi = clo;
                lo++;
                hi--;
                continue;
            }

            int stridelo = 1 + (clo >= 0xD800 && clo <= 0xDBFF);

            int stridehi = 1;
            if (chi >= 0xDC00 && chi <= 0xDFFF)
            {
                chi = *--hi;
                stridehi++;
            }
            if (lo >= hi){
                if (lo>hi){
                    hadErrors=true;
                }
                break;
            }

            if (stridelo == stridehi)
            {   int stmp;

                assert(stridelo == 2);
                assert(stmp.sizeof == 2 * (*lo).sizeof);
                stmp = *cast(int*)lo;
                *cast(int*)lo = *cast(int*)hi;
                *cast(int*)hi = stmp;
                lo += stridelo;
                hi--;
                continue;
            }

            /* Shift the whole array. This is woefully inefficient
             */
            memcpy(tmp.ptr, hi, stridehi * wchar.sizeof);
            memcpy(hi + cast(int) stridehi - cast(int) stridelo, lo, stridelo * wchar.sizeof);
            memmove(lo + stridehi, lo + stridelo , (hi - (lo + stridelo)) * wchar.sizeof);
            memcpy(lo, tmp.ptr, stridehi * wchar.sizeof);

            lo += stridehi;
            hi = hi - 1 + (cast(int) stridehi - cast(int) stridelo);
        }
    }
    if (hadErrors)
        throw new Exception("invalid UTF-16 sequence",__FILE__,__LINE__);
    return *cast(Array*)(&a);
}

unittest
{
    alias wchar[] wstring;
    wstring a = "abcd";
    wstring r;

    r = a.dup.reverse;
    assert(r == "dcba");

    a = "a\U00012356\U00012346c";
    r = a.dup.reverse;
    assert(r == "c\U00012346\U00012356a");

    a = "ab\U00012345c";
    r = a.dup.reverse;
    assert(r == "c\U00012345ba");
}

// %% Had to move _adCmpChar to the beginning of the file
// due to a extern/static symbol conflict on darwin...
/***************************************
 * Support for array compare test.
 */

extern (C) int _adCmpChar(Array a1, Array a2)
{
version (Asm86)
{
    asm
    {   naked                   ;

        push    EDI             ;
        push    ESI             ;

        mov    ESI,a1+4[4+ESP]  ;
        mov    EDI,a2+4[4+ESP]  ;

        mov    ECX,a1[4+ESP]    ;
        mov    EDX,a2[4+ESP]    ;

        cmp     ECX,EDX         ;
        jb      GotLength       ;

        mov     ECX,EDX         ;

GotLength:
        cmp    ECX,4            ;
        jb    DoBytes           ;

        // Do alignment if neither is dword aligned
        test    ESI,3           ;
        jz    Aligned           ;

        test    EDI,3           ;
        jz    Aligned           ;
DoAlign:
        mov    AL,[ESI]         ; //align ESI to dword bounds
        mov    DL,[EDI]         ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        inc    ESI              ;
        inc    EDI              ;

        test    ESI,3           ;

        lea    ECX,[ECX-1]      ;
        jnz    DoAlign          ;
Aligned:
        mov    EAX,ECX          ;

        // do multiple of 4 bytes at a time

        shr    ECX,2            ;
        jz    TryOdd            ;

        repe                    ;
        cmpsd                   ;

        jnz    UnequalQuad      ;

TryOdd:
        mov    ECX,EAX          ;
DoBytes:
        // if still equal and not end of string, do up to 3 bytes slightly
        // slower.

        and    ECX,3            ;
        jz    Equal             ;

        repe                    ;
        cmpsb                   ;

        jnz    Unequal          ;
Equal:
        mov    EAX,a1[4+ESP]    ;
        mov    EDX,a2[4+ESP]    ;

        sub    EAX,EDX          ;
        pop    ESI              ;

        pop    EDI              ;
        ret                     ;

UnequalQuad:
        mov    EDX,[EDI-4]      ;
        mov    EAX,[ESI-4]      ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        cmp    AH,DH            ;
        jnz    Unequal          ;

        shr    EAX,16           ;

        shr    EDX,16           ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        cmp    AH,DH            ;
Unequal:
        sbb    EAX,EAX          ;
        pop    ESI              ;

        or     EAX,1            ;
        pop    EDI              ;

        ret                     ;
    }
}
else
{
    int len;
    int c;

    debug(adi) printf("adCmpChar()\n");
    len = a1.length;
    if (a2.length < len)
        len = a2.length;
    c = memcmp(cast(char *)a1.ptr, cast(char *)a2.ptr, len);
    if (!c)
        c = cast(int)a1.length - cast(int)a2.length;
    return c;
}
}

unittest
{
    debug(adi) printf("array.CmpChar unittest\n");

    auto a = "hello"c;

    assert(a >  "hel");
    assert(a >= "hel");
    assert(a <  "helloo");
    assert(a <= "helloo");
    assert(a >  "betty");
    assert(a >= "betty");
    assert(a == "hello");
    assert(a <= "hello");
    assert(a >= "hello");
}


/**********************************************
 * Support for array.reverse property.
 */

extern (C) Array _adReverse(Array a, size_t szelem)
    out (result)
    {
        assert(result is a);
    }
    body
    {
        if (a.length >= 2)
        {
            byte*    tmp;
            byte[16] buffer;

            void* lo = a.ptr;
            void* hi = a.ptr + (a.length - 1) * szelem;

            tmp = buffer.ptr;
            if (szelem > 16)
            {
                //version (Win32)
                    tmp = cast(byte*) alloca(szelem);
                //else
                    //tmp = gc_malloc(szelem);
            }

            for (; lo < hi; lo += szelem, hi -= szelem)
            {
                memcpy(tmp, lo,  szelem);
                memcpy(lo,  hi,  szelem);
                memcpy(hi,  tmp, szelem);
            }

            version (Win32)
            {
            }
            else
            {
                //if (szelem > 16)
                    // BUG: bad code is generate for delete pointer, tries
                    // to call delclass.
                    //gc_free(tmp);
            }
        }
        return a;
    }

unittest
{
    debug(adi) printf("array.reverse.unittest\n");

    int[] a = new int[5];
    int[] b;
    size_t i;

    for (i = 0; i < 5; i++)
        a[i] = i;
    b = a.reverse;
    assert(b is a);
    for (i = 0; i < 5; i++)
        assert(a[i] == 4 - i);

    struct X20
    {   // More than 16 bytes in size
        int a;
        int b, c, d, e;
    }

    X20[] c = new X20[5];
    X20[] d;

    for (i = 0; i < 5; i++)
    {   c[i].a = i;
        c[i].e = 10;
    }
    d = c.reverse;
    assert(d is c);
    for (i = 0; i < 5; i++)
    {
        assert(c[i].a == 4 - i);
        assert(c[i].e == 10);
    }
}

/**********************************************
 * Sort array of chars.
 */

extern (C) char[] _adSortChar(char[] a)
{
    if (a.length > 1)
    {
        dchar[] da = toUTF32(a);
        da.sort;
        size_t i = 0;
        foreach (dchar d; da)
        {   char[4] buf;
            auto t = toUTF8(buf, d);
            a[i .. i + t.length] = t[];
            i += t.length;
        }
        delete da;
    }
    return a;
}

/**********************************************
 * Sort array of wchars.
 */

extern (C) wchar[] _adSortWchar(wchar[] a)
{
    if (a.length > 1)
    {
        dchar[] da = toUTF32(a);
        da.sort;
        size_t i = 0;
        foreach (dchar d; da)
        {   wchar[2] buf;
            auto t = toUTF16(buf, d);
            a[i .. i + t.length] = t[];
            i += t.length;
        }
        delete da;
    }
    return a;
}

/***************************************
 * Support for array equality test.
 */

extern (C) int _adEq(Array a1, Array a2, TypeInfo ti)
{
    /+
     + TODO: Re-enable once the correct TypeInfo is passed:
     +       http://d.puremagic.com/issues/show_bug.cgi?id=2161
     +
    debug(adi) printf("_adEq(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);

    if (a1.length != a2.length)
        return 0; // not equal
    if (a1.ptr == a2.ptr)
        return 1; // equal

    // We should really have a ti.isPOD() check for this
    if (ti.tsize() != 1)
        return ti.equals(&a1, &a2);
    return memcmp(a1.ptr, a2.ptr, a1.length) == 0;
    +/
    debug(adi) printf("_adEq(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
    if (a1.length != a2.length)
        return 0; // not equal
    auto sz = ti.tsize();
    auto p1 = a1.ptr;
    auto p2 = a2.ptr;

    if (sz == 1)
        // We should really have a ti.isPOD() check for this
        return (memcmp(p1, p2, a1.length) == 0);

    for (size_t i = 0; i < a1.length; i++)
    {
        if (!ti.equals(p1 + i * sz, p2 + i * sz))
            return 0; // not equal
    }
    return 1; // equal
}

unittest
{
    debug(adi) printf("array.Eq unittest\n");

    auto a = "hello"c;

    assert(a != "hel");
    assert(a != "helloo");
    assert(a != "betty");
    assert(a == "hello");
    assert(a != "hxxxx");
}

/***************************************
 * Support for array compare test.
 */

extern (C) int _adCmp(Array a1, Array a2, TypeInfo ti)
{
    /+
     + TODO: Re-enable once the correct TypeInfo is passed:
     +       http://d.puremagic.com/issues/show_bug.cgi?id=2161
     +
    debug(adi) printf("adCmp()\n");

    if (a1.ptr == a2.ptr &&
        a1.length == a2.length)
        return 0;

    auto len = a1.length;
    if (a2.length < len)
        len = a2.length;

    // We should really have a ti.isPOD() check for this
    if (ti.tsize() != 1)
        return ti.compare(&a1, &a2);
    auto c = memcmp(a1.ptr, a2.ptr, len);
    if (c)
        return c;
    if (a1.length == a2.length)
        return 0;
    return a1.length > a2.length ? 1 : -1;
    +/
    debug(adi) printf("adCmp()\n");
    auto len = a1.length;
    if (a2.length < len)
        len = a2.length;
    auto sz = ti.tsize();
    void *p1 = a1.ptr;
    void *p2 = a2.ptr;

    if (sz == 1)
    {   // We should really have a ti.isPOD() check for this
        auto c = memcmp(p1, p2, len);
        if (c)
            return c;
    }
    else
    {
        for (size_t i = 0; i < len; i++)
        {
            auto c = ti.compare(p1 + i * sz, p2 + i * sz);
            if (c)
                return c;
        }
    }
    if (a1.length == a2.length)
        return 0;
    return (a1.length > a2.length) ? 1 : -1;
}

unittest
{
    debug(adi) printf("array.Cmp unittest\n");

    auto a = "hello"c;

    assert(a >  "hel");
    assert(a >= "hel");
    assert(a <  "helloo");
    assert(a <= "helloo");
    assert(a >  "betty");
    assert(a >= "betty");
    assert(a == "hello");
    assert(a <= "hello");
    assert(a >= "hello");
}
