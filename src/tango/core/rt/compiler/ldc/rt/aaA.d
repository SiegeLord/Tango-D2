//_ aaA.d

/**
 * Part of the D programming language runtime library.
 * Implementation of associative arrays.
 */

/*
 *  Copyright (C) 2000-2008 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
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

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 *  Modified by Tomas Lindquist Olsen <tomas@famolsen.dk> for use with LDC.
 */
module rt.aaA;

private
{
    import tango.stdc.stdarg;
    import tango.stdc.string : memcmp, memcpy;

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
}

// Auto-rehash and pre-allocate - Dave Fladebo

static size_t[] prime_list = [
               97UL,            389UL,
            1_543UL,          6_151UL,
           24_593UL,         98_317UL,
          393_241UL,      1_572_869UL,
        6_291_469UL,     25_165_843UL,
      100_663_319UL,    402_653_189UL,
    1_610_612_741UL,  4_294_967_291UL,
//  8_589_934_513UL, 17_179_869_143UL
];

struct aaA
{
    aaA *left;
    aaA *right;
    hash_t hash;
    /* key   */
    /* value */
}

struct BB
{
    aaA*[] b;
    size_t nodes;       // total number of aaA nodes
    TypeInfo keyti;     // TODO: replace this with TypeInfo_AssociativeArray when available in _aaGet() 
}

/* This is the type actually seen by the programmer, although
 * it is completely opaque.
 */

// LDC doesn't pass structs in registers so no need to wrap it ...
alias BB* AA;

/**********************************
 * Align to next pointer boundary, so that
 * GC won't be faced with misaligned pointers
 * in value.
 */

size_t aligntsize(size_t tsize)
{
    return (tsize + size_t.sizeof - 1) & ~(size_t.sizeof - 1);
}

extern (C):

/*************************************************
 * Invariant for aa.
 */

/+
void _aaInvAh(aaA*[] aa)
{
    for (size_t i = 0; i < aa.length; i++)
    {
        if (aa[i])
            _aaInvAh_x(aa[i]);
    }
}

private int _aaCmpAh_x(aaA *e1, aaA *e2)
{   int c;

    c = e1.hash - e2.hash;
    if (c == 0)
    {
        c = e1.key.length - e2.key.length;
        if (c == 0)
            c = memcmp((char *)e1.key, (char *)e2.key, e1.key.length);
    }
    return c;
}

private void _aaInvAh_x(aaA *e)
{
    hash_t key_hash;
    aaA *e1;
    aaA *e2;

    key_hash = getHash(e.key);
    assert(key_hash == e.hash);

    while (1)
    {   int c;

        e1 = e.left;
        if (e1)
        {
            _aaInvAh_x(e1);             // ordinary recursion
            do
            {
                c = _aaCmpAh_x(e1, e);
                assert(c < 0);
                e1 = e1.right;
            } while (e1 != null);
        }

        e2 = e.right;
        if (e2)
        {
            do
            {
                c = _aaCmpAh_x(e, e2);
                assert(c < 0);
                e2 = e2.left;
            } while (e2 != null);
            e = e.right;                // tail recursion
        }
        else
            break;
    }
}
+/

/****************************************************
 * Determine number of entries in associative array.
 */

size_t _aaLen(AA aa)
in
{
    //printf("_aaLen()+\n");
    //_aaInv(aa);
}
out (result)
{
    size_t len = 0;

    void _aaLen_x(aaA* ex)
    {
        auto e = ex;
        len++;

        while (1)
        {
            if (e.right)
               _aaLen_x(e.right);
            e = e.left;
            if (!e)
                break;
            len++;
        }
    }

    if (aa)
    {
        foreach (e; aa.b)
        {
            if (e)
                _aaLen_x(e);
        }
    }
    assert(len == result);

    //printf("_aaLen()-\n");
}
body
{
    return aa ? aa.nodes : 0;
}


/*************************************************
 * Get pointer to value in associative array indexed by key.
 * Add entry for key if it is not already there.
 */

void* _aaGet(AA* aa_arg, TypeInfo keyti, size_t valuesize, void* pkey)
in
{
    assert(aa_arg);
}
out (result)
{
    assert(result);
    assert(*aa_arg);
    assert((*aa_arg).b.length);
    //assert(_aaInAh(*aa, key));
}
body
{
    //auto pkey = cast(void *)(&valuesize + 1);
    size_t i;
    aaA *e;
    auto keysize = aligntsize(keyti.tsize());

    if (!*aa_arg)
        *aa_arg = new BB();
    auto aa = *aa_arg;
    aa.keyti = keyti;

    if (!aa.b.length)
    {
        alias aaA *pa;
        auto len = prime_list[0];

        aa.b = new pa[len];
    }

    auto key_hash = keyti.getHash(pkey);
    //printf("hash = %d\n", key_hash);
    i = key_hash % aa.b.length;
    auto pe = &aa.b[i];
    while ((e = *pe) !is null)
    {
        if (key_hash == e.hash)
        {
            auto c = keyti.compare(pkey, e + 1);
            if (c == 0)
                goto Lret;
            pe = (c < 0) ? &e.left : &e.right;
        }
        else
            pe = (key_hash < e.hash) ? &e.left : &e.right;
    }

    // Not found, create new elem
    //printf("create new one\n");
    size_t size = aaA.sizeof + keysize + valuesize;
    e = cast(aaA *) gc_calloc(size);
    memcpy(e + 1, pkey, keysize);
    e.hash = key_hash;
    *pe = e;

    auto nodes = ++aa.nodes;
    //printf("length = %d, nodes = %d\n", (*aa).length, nodes);
    if (nodes > aa.b.length * 4)
    {
        _aaRehash(aa_arg,keyti);
    }

Lret:
    return cast(void *)(e + 1) + keysize;
}


/*************************************************
 * Get pointer to value in associative array indexed by key.
 * Returns null if it is not already there.
 * Used for both "aa[key]" and "key in aa"
 * Returns:
 *      null    not in aa
 *      !=null  in aa, return pointer to value
 */

void* _aaIn(AA aa, TypeInfo keyti, void *pkey)
in
{
}
out (result)
{
    //assert(result == 0 || result == 1);
}
body
{
    if (aa)
    {
        //auto pkey = cast(void *)(&keyti + 1);

        //printf("_aaIn(), .length = %d, .ptr = %x\n", aa.length, cast(uint)aa.ptr);
        auto len = aa.b.length;

        if (len)
        {
            auto key_hash = keyti.getHash(pkey);
            //printf("hash = %d\n", key_hash);
            size_t i = key_hash % len;
            auto e = aa.b[i];
            while (e !is null)
            {
                if (key_hash == e.hash)
                {
                    auto c = keyti.compare(pkey, e + 1);
                    if (c == 0)
                        return cast(void *)(e + 1) + aligntsize(keyti.tsize());
                    e = (c < 0) ? e.left : e.right;
                }
                else
                    e = (key_hash < e.hash) ? e.left : e.right;
            }
        }
    }

    // Not found
    return null;
}

/*************************************************
 * Delete key entry in aa[].
 * If key is not in aa[], do nothing.
 */

void _aaDel(AA aa, TypeInfo keyti, void *pkey)
{
    //auto pkey = cast(void *)(&keyti + 1);
    aaA *e;

    if (aa && aa.b.length)
    {
        auto key_hash = keyti.getHash(pkey);
        //printf("hash = %d\n", key_hash);
        size_t i = key_hash % aa.b.length;
        auto pe = &aa.b[i];
        while ((e = *pe) !is null) // null means not found
        {
            if (key_hash == e.hash)
            {
                auto c = keyti.compare(pkey, e + 1);
                if (c == 0)
                {
                    if (!e.left && !e.right)
                    {
                        *pe = null;
                    }
                    else if (e.left && !e.right)
                    {
                        *pe = e.left;
                         e.left = null;
                    }
                    else if (!e.left && e.right)
                    {
                        *pe = e.right;
                         e.right = null;
                    }
                    else
                    {
                        *pe = e.left;
                        e.left = null;
                        do
                            pe = &(*pe).right;
                        while (*pe);
                        *pe = e.right;
                        e.right = null;
                    }

                    aa.nodes--;
                    gc_free(e);

                    break;
                }
                pe = (c < 0) ? &e.left : &e.right;
            }
            else
                pe = (key_hash < e.hash) ? &e.left : &e.right;
        }
    }
}


/********************************************
 * Produce array of values from aa.
 * The actual type is painted on the return value by the frontend
 * This means the returned length should be the number of elements
 */

void[] _aaValues(AA aa, size_t keysize, size_t valuesize)
in
{
    assert(keysize == aligntsize(keysize));
}
body
{
    size_t resi;
    void[] a;

    void _aaValues_x(aaA* e)
    {
        do
        {
            memcpy(a.ptr + resi * valuesize,
                   cast(byte*)e + aaA.sizeof + keysize,
                   valuesize);
            resi++;
            if (e.left)
            {   if (!e.right)
                {   e = e.left;
                    continue;
                }
                _aaValues_x(e.left);
            }
            e = e.right;
        } while (e !is null);
    }

    if (aa)
    {
        auto len = _aaLen(aa);
        auto ptr = cast(byte*) gc_malloc(len * valuesize,
                                      valuesize < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        a = ptr[0 .. len];
        resi = 0;
        foreach (e; aa.b)
        {
            if (e)
                _aaValues_x(e);
        }
        assert(resi == a.length);
    }
    return a;
}


/********************************************
 * Rehash an array.
 */

void* _aaRehash(AA* paa, TypeInfo keyti)
in
{
    //_aaInvAh(paa);
}
out (result)
{
    //_aaInvAh(result);
}
body
{
    BB newb;

    void _aaRehash_x(aaA* olde)
    {
        while (1)
        {
            auto left = olde.left;
            auto right = olde.right;
            olde.left = null;
            olde.right = null;

            aaA *e;

            //printf("rehash %p\n", olde);
            auto key_hash = olde.hash;
            size_t i = key_hash % newb.b.length;
            auto pe = &newb.b[i];
            while ((e = *pe) !is null)
            {
                //printf("\te = %p, e.left = %p, e.right = %p\n", e, e.left, e.right);
                assert(e.left != e);
                assert(e.right != e);
                if (key_hash == e.hash)
                {
                    auto c = keyti.compare(olde + 1, e + 1);
                    assert(c != 0);
                    pe = (c < 0) ? &e.left : &e.right;
                }
                else
                    pe = (key_hash < e.hash) ? &e.left : &e.right;
            }
            *pe = olde;

            if (right)
            {
                if (!left)
                {   olde = right;
                    continue;
                }
                _aaRehash_x(right);
            }
            if (!left)
                break;
            olde = left;
        }
    }

    //printf("Rehash\n");
    if (*paa)
    {
        auto aa = *paa;
        auto len = _aaLen(aa);
        if (len)
        {   size_t i;

            for (i = 0; i < prime_list.length - 1; i++)
            {
                if (len <= prime_list[i])
                    break;
            }
            len = prime_list[i];
            newb.b = new aaA*[len];
            newb.keyti = keyti;

            foreach (e; aa.b)
            {
                if (e)
                    _aaRehash_x(e);
            }

            newb.nodes = (*aa).nodes;
        }

        **paa = newb;
    }
    return *paa;
}


/********************************************
 * Produce array of N byte keys from aa.
 * The actual type is painted on the return value by the frontend
 * This means the returned length should be the number of elements
 */

void[] _aaKeys(AA aa, size_t keysize)
{
    byte[] res;
    size_t resi;

    void _aaKeys_x(aaA* e)
    {
        do
        {
            memcpy(&res[resi * keysize], cast(byte*)(e + 1), keysize);
            resi++;
            if (e.left)
            {   if (!e.right)
                {   e = e.left;
                    continue;
                }
                _aaKeys_x(e.left);
            }
            e = e.right;
        } while (e !is null);
    }

    auto len = _aaLen(aa);
    if (!len)
        return null;
    res = (cast(byte*) gc_malloc(len * keysize,
                                 !(aa.keyti.flags() & 1) ? BlkAttr.NO_SCAN : 0)) [0 .. len * keysize];
    resi = 0;
    foreach (e; aa.b)
    {
        if (e)
            _aaKeys_x(e);
    }
    assert(resi == len);

    return res.ptr[0 .. len];
}


/**********************************************
 * 'apply' for associative arrays - to support foreach
 */

// dg is D, but _aaApply() is C
extern (D) typedef int delegate(void *) dg_t;

int _aaApply(AA aa, size_t keysize, dg_t dg)
in
{
    assert(aligntsize(keysize) == keysize);
}
body
{   int result;

    //printf("_aaApply(aa = x%llx, keysize = %d, dg = x%llx)\n", aa, keysize, dg);

    int treewalker(aaA* e)
    {   int result;

        do
        {
            //printf("treewalker(e = %p, dg = x%llx)\n", e, dg);
            result = dg(cast(void *)(e + 1) + keysize);
            if (result)
                break;
            if (e.right)
            {   if (!e.left)
                {
                    e = e.right;
                    continue;
                }
                result = treewalker(e.right);
                if (result)
                    break;
            }
            e = e.left;
        } while (e);

        return result;
    }

    if (aa)
    {
        foreach (e; aa.b)
        {
            if (e)
            {
                result = treewalker(e);
                if (result)
                    break;
            }
        }
    }
    return result;
}

// dg is D, but _aaApply2() is C
extern (D) typedef int delegate(void *, void *) dg2_t;

int _aaApply2(AA aa, size_t keysize, dg2_t dg)
in
{
    assert(aligntsize(keysize) == keysize);
}
body
{   int result;

    //printf("_aaApply(aa = x%llx, keysize = %d, dg = x%llx)\n", aa, keysize, dg);

    int treewalker(aaA* e)
    {   int result;

        do
        {
            //printf("treewalker(e = %p, dg = x%llx)\n", e, dg);
            result = dg(cast(void *)(e + 1), cast(void *)(e + 1) + keysize);
            if (result)
                break;
            if (e.right)
            {   if (!e.left)
                {
                    e = e.right;
                    continue;
                }
                result = treewalker(e.right);
                if (result)
                    break;
            }
            e = e.left;
        } while (e);

        return result;
    }

    if (aa)
    {
        foreach (e; aa.b)
        {
            if (e)
            {
                result = treewalker(e);
                if (result)
                    break;
            }
        }
    }
    return result;
}

int _aaEq(AA aa, AA ab, TypeInfo_AssociativeArray ti)
{
    return ti.equals(&aa, &ab);
}

/***********************************
 * Construct an associative array of type ti from
 * length pairs of key/value pairs.
 */

/+

extern (C)
BB* _d_assocarrayliteralT(TypeInfo_AssociativeArray ti, size_t length, ...)
{
    auto valuesize = ti.next.tsize();           // value size
    auto keyti = ti.key;
    auto keysize = keyti.tsize();               // key size
    BB* result;

    //printf("_d_assocarrayliteralT(keysize = %d, valuesize = %d, length = %d)\n", keysize, valuesize, length);
    //printf("tivalue = %.*s\n", ti.next.classinfo.name);
    if (length == 0 || valuesize == 0 || keysize == 0)
    {
        ;
    }
    else
    {
        va_list q;
        va_start!(size_t)(q, length);

        result = new BB();
        size_t i;

        for (i = 0; i < prime_list.length - 1; i++)
        {
            if (length <= prime_list[i])
                break;
        }
        auto len = prime_list[i];
        result.b = new aaA*[len];

        size_t keystacksize   = (keysize   + int.sizeof - 1) & ~(int.sizeof - 1);
        size_t valuestacksize = (valuesize + int.sizeof - 1) & ~(int.sizeof - 1);

        size_t keytsize = aligntsize(keysize);

        for (size_t j = 0; j < length; j++)
        {   void* pkey = q;
            q += keystacksize;
            void* pvalue = q;
            q += valuestacksize;
            aaA* e;

            auto key_hash = keyti.getHash(pkey);
            //printf("hash = %d\n", key_hash);
            i = key_hash % len;
            auto pe = &result.b[i];
            while (1)
            {
                e = *pe;
                if (!e)
                {
                    // Not found, create new elem
                    //printf("create new one\n");
                    e = cast(aaA *) cast(void*) new void[aaA.sizeof + keytsize + valuesize];
                    memcpy(e + 1, pkey, keysize);
                    e.hash = key_hash;
                    *pe = e;
                    result.nodes++;
                    break;
                }
                if (key_hash == e.hash)
                {
                    auto c = keyti.compare(pkey, e + 1);
                    if (c == 0)
                        break;
                    pe = (c < 0) ? &e.left : &e.right;
                }
                else
                    pe = (key_hash < e.hash) ? &e.left : &e.right;
            }
            memcpy(cast(void *)(e + 1) + keytsize, pvalue, valuesize);
        }

        va_end(q);
    }
    return result;
}

+/
