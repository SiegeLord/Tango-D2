/**
 * This module contains all functions related to an object's lifetime:
 * allocation, resizing, deallocation, and finalization.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
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
 * Authors:   Walter Bright, Sean Kelly
 */
module lifetime;


private
{
    import tango.stdc.stdlib;
    import tango.stdc.string;
    import tango.stdc.stdarg;
    import tango.stdc.stdbool; // TODO: remove this when the old bit code goes away
    debug import tango.stdc.stdio;
}


private
{
    enum BlkAttr : uint
    {
        FINALIZE = 0b0000_0001,
        NO_SCAN  = 0b0000_0010,
        NO_MOVE  = 0b0000_0100,
        ALL_BITS = 0b1111_1111
    }

    extern (C) uint gc_getAttr( void* p );
    extern (C) uint gc_setAttr( void* p, uint a );
    extern (C) uint gc_clrAttr( void* p, uint a );

    extern (C) void* gc_malloc( size_t sz, uint ba = 0 );
    extern (C) void* gc_calloc( size_t sz, uint ba = 0 );
    extern (C) void  gc_free( void* p );

    extern (C) size_t gc_sizeOf( void* p );

    extern (C) bool onCollectResource( Object o );
    extern (C) void onFinalizeError( ClassInfo c, Exception e );
    extern (C) void onOutOfMemoryError();

    extern (C) void _d_monitorrelease(Object h);
}


/**
 *
 */
extern (C) Object _d_newclass(ClassInfo ci)
{
    void* p;

    debug printf("_d_newclass(ci = %p)\n", ci);

    if (ci.flags & 1) // if COM object
    {
        p = cast(Object)tango.stdc.stdlib.malloc(ci.init.length);
        if (!p)
            onOutOfMemoryError();
    }
    else
    {
        p = gc_malloc(ci.init.length, BlkAttr.FINALIZE);
        debug printf(" p = %p\n", p);
    }

    debug
    {
        printf("p = %p\n", p);
        printf("ci = %p, ci.init = %p, len = %d\n", ci, ci.init, ci.init.length);
        printf("vptr = %p\n", *cast(void**) ci.init);
        printf("vtbl[0] = %p\n", (*cast(void***) ci.init)[0]);
        printf("vtbl[1] = %p\n", (*cast(void***) ci.init)[1]);
        printf("init[0] = %x\n", (cast(uint*) ci.init)[0]);
        printf("init[1] = %x\n", (cast(uint*) ci.init)[1]);
        printf("init[2] = %x\n", (cast(uint*) ci.init)[2]);
        printf("init[3] = %x\n", (cast(uint*) ci.init)[3]);
        printf("init[4] = %x\n", (cast(uint*) ci.init)[4]);
    }

    // initialize it
    (cast(byte*) p)[0 .. ci.init.length] = ci.init[];

    debug printf("initialization done\n");
    return cast(Object) p;
}


/**
 *
 */
extern (C) void _d_delinterface(void** p)
{
    if (*p)
    {
        Interface* pi = **cast(Interface ***)*p;
        Object     o  = cast(Object)(*p - pi.offset);

        _d_delclass(&o);
        *p = null;
    }
}


// used for deletion
private extern (D) alias void (*fp_t)(Object);


/**
 *
 */
extern (C) void _d_delclass(Object* p)
{
    if (*p)
    {
        debug printf("_d_delclass(%p)\n", *p);

        version(0)
        {
            ClassInfo **pc = cast(ClassInfo **)*p;
            if (*pc)
            {
                ClassInfo c = **pc;

                if (c.deallocator)
                {
                    cr_finalize(*p);
                    fp_t fp = cast(fp_t)c.deallocator;
                    (*fp)(*p); // call deallocator
                    *p = null;
                    return;
                }
            }
        }
        gc_free(*p);
        *p = null;
    }
}


/**
 *
 */
extern (C) Array _d_new(size_t length, size_t size)
{
    void *p;
    Array result;

    debug printf("_d_new(length = %d, size = %d)\n", length, size);
    /*
    if (length == 0 || size == 0)
    result = 0;
    else
    */
    if (length && size)
    {
        p = gc_malloc(length * size + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        debug printf(" p = %p\n", p);
        memset(p, 0, length * size);
        result.length = length;
        result.data = cast(byte*)p;
    }
    return result;
}


/**
 *
 */
extern (C) Array _d_newarrayip(size_t length, size_t size, void* init)
{
    Array result;

    if (length && size)
    {
        result.length = length;
        result.data = cast(byte*) gc_malloc(length * size + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        if (size == 1)
            memset(result.data, * cast(ubyte*) init, length);
        else
        {
            void* p = result.data;
            for (uint u = 0; u < length; u++)
            {
                memcpy(p, init, size);
                p += size;
            }
        }
    }
    return result;
}


/**
 *
 */
extern (C) void[] _d_newmp(size_t size, int ndims, size_t* pdim)
{
    void[] result = void;

    debug printf("_d_newm(size = %d, ndims = %d)\n", size, ndims);

    if (size == 0 || ndims == 0)
        result = null;
    else
    {

        void[] foo(size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            if (ndims == 1)
            {   p = gc_malloc(dim * size + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0)[0 .. dim];
                memset(p.ptr, 0, dim * size + 1);
            }
            else
            {
                p = gc_malloc(dim * (void[]).sizeof + 1)[0 .. dim]; // always scan
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        result = foo(pdim, ndims);
        debug printf("result = %llx\n", result);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                printf("index %d: %d\n", i, pdim[i]);
            }
        }
    }
    return result;
}


/**
 *
 */
extern (C) void[] _d_newarraymip(size_t size, int ndims, size_t* pdim, size_t mult, void* pinit)
{
    void[] result = void;

    debug printf("_d_newarraymi(size = %d, ndims = %d)\n", size, ndims);

    if (size == 0 || ndims == 0)
        result = null;
    else
    {

        void[] foo(size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            if (ndims == 1)
            {   p = gc_malloc(dim * mult * size + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0)[0 .. dim];
                if (size == 1)
                    memset(p.ptr, *cast(ubyte*)pinit, dim);
                else
                {
                    size_t n = dim * mult;
                    for (size_t u = 0; u < n; u++)
                    {
                        memcpy(p.ptr + u * size, pinit, size);
                    }
                }
            }
            else
            {
                p = gc_malloc(dim * (void[]).sizeof + 1)[0 .. dim]; // always scan
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        result = foo(pdim, ndims);
        debug printf("result = %llx\n", result);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                printf("index %d: %d\n", i, pdim[i]);
                printf("init = %d\n", *cast(int*)pinit);
            }
        }
    }
    return result;
}


/**
 *
 */
extern (C) Array _d_newbitarray(size_t length, bit value)
{
    void *p;
    Array result;

    debug printf("_d_newbitarray(length = %d, value = %d)\n", length, value);
    /*
    if (length == 0)
    result = 0;
    else
    */
    if (length)
    {
        size_t size = ((length + 31) >> 5) * 4 + 1; // number of bytes
        ubyte  fill = value ? 0xFF : 0; // (not sure what the extra byte is for...)

        p = gc_malloc(size, BlkAttr.NO_SCAN);
        debug printf(" p = %p\n", p);
        memset(p, fill, size);
        result.length = length;
        result.data = cast(byte*)p;
    }
    return result;
}


/**
 *
 */
struct Array
{
    size_t length;
    byte*  data;
}


/**
 *
 */
extern (C) void _d_delarray(Array *p)
{
    if (p)
    {
        assert(!p.length || p.data);

        if (p.data)
            gc_free(p.data);
        p.data = null;
        p.length = 0;
    }
}


/**
 *
 */
extern (C) void _d_delmemory(void* *p)
{
    if (*p)
    {
        gc_free(*p);
        *p = null;
    }
}


/**
 *
 */
extern (C) void _d_callfinalizer(void* p)
{
    cr_finalize( p );
}


/**
 *
 */
extern (C) void cr_finalize(void* p, bool det = true)
{
    debug printf("cr_finalize(p = %p)\n", p);

    if (p) // not necessary if called from gc
    {
        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;

            try
            {
                if (det || onCollectResource(cast(Object)p))
                {
                    do
                    {
                        if (c.destructor)
                        {
                            fp_t fp = cast(fp_t)c.destructor;
                            (*fp)(cast(Object)p); // call destructor
                        }
                        c = c.base;
                    } while (c);
                }
                if ((cast(void**)p)[1]) // if monitor is not null
                    _d_monitorrelease(cast(Object)p);
            }
            catch (Exception e)
            {
                onFinalizeError(**pc, e);
            }
            finally
            {
                *pc = null; // zero vptr
            }
        }
    }
}


/**
 * Resize dynamic arrays with 0 initializers.
 */
extern (C) byte[] _d_arraysetlength(size_t newlength, size_t sizeelem, Array *p)
in
{
    assert(sizeelem);
    assert(!p.length || p.data);
}
body
{
    byte* newdata;

    debug
    {
        printf("_d_arraysetlength(p = %p, sizeelem = %d, newlength = %d)\n", p, sizeelem, newlength);
        if (p)
            printf("\tp.data = %p, p.length = %d\n", p.data, p.length);
    }

    if (newlength)
    {
        version (GNU)
        {
                // required to output the label;
            static char x = 0;
            if (x)
                goto Loverflow;
        }
        version (D_InlineAsm_X86)
        {
            size_t newsize = void;

            asm
            {
                mov EAX, newlength;
                mul EAX, sizeelem;
                mov newsize, EAX;
                jc  Loverflow;
            }
        }
        else
        {
            size_t newsize = sizeelem * newlength;

            if (newsize / newlength != sizeelem)
                goto Loverflow;
        }

        debug printf("newsize = %x, newlength = %x\n", newsize, newlength);

        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                size_t size = p.length * sizeelem;
                size_t cap  = gc_sizeOf(p.data);

                if (cap <= newsize)
                {
                    newdata = cast(byte *)gc_malloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
                    newdata[0 .. size] = p.data[0 .. size];
                }
                newdata[size .. newsize] = 0;
            }
        }
        else
        {
            newdata = cast(byte *)gc_calloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        }
    }
    else
    {
        newdata = p.data;
    }

    p.data = newdata;
    p.length = newlength;
    return newdata[0 .. newlength];

Loverflow:
    onOutOfMemoryError();
}


/**
 * Resize arrays for non-zero initializers.
 * (obsolete, replaced by _d_arraysetlength3)
 */
extern (C) byte[] _d_arraysetlength2p(size_t newlength, size_t sizeelem, Array *p, void * init)
in
{
    assert(sizeelem);
    assert(!p.length || p.data);
}
body
{
    byte* newdata;

    debug
    {
        printf("_d_arraysetlength2(p = %p, sizeelem = %d, newlength = %d)\n", p, sizeelem, newlength);
        if (p)
            printf("\tp.data = %p, p.length = %d\n", p.data, p.length);
    }

    if (newlength)
    {
        version (GNU)
        {
            // required to output the label;
            static char x = 0;
            if (x)
                goto Loverflow;
        }
        version (D_InlineAsm_X86)
        {
            size_t newsize = void;

            asm
            {
                mov EAX, newlength;
                mul EAX, sizeelem;
                mov newsize, EAX;
                jc  Loverflow;
            }
        }
        else
        {
            size_t newsize = sizeelem * newlength;

            if (newsize / newlength != sizeelem)
                goto Loverflow;
        }

        debug printf("newsize = %x, newlength = %x\n", newsize, newlength);

        size_t size = p.length * sizeelem;

        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                size_t cap = gc_sizeOf(p.data);

                if (cap <= newsize)
                {
                    newdata = cast(byte *)gc_malloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
                    newdata[0 .. size] = p.data[0 .. size];
                }
            }
        }
        else
        {
            newdata = cast(byte *)gc_malloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        }

        if (newsize > size)
        {
            if (sizeelem == 1)
                newdata[size .. newsize] = *(cast(byte*)init);
            else
            {
                for (size_t u = size; u < newsize; u += sizeelem)
                {
                    memcpy(newdata + u, init, sizeelem);
                }
            }
        }
    }
    else
    {
        newdata = p.data;
    }

    p.data = newdata;
    p.length = newlength;
    return newdata[0 .. newlength];

Loverflow:
    onOutOfMemoryError();
}


/**
 * Resize arrays for non-zero initializers.
 *      p               pointer to array lvalue to be updated
 *      newlength       new .length property of array
 *      sizeelem        size of each element of array
 *      initsize        size of initializer
 *      ...             initializer
 */
extern (C) byte[] _d_arraysetlength3p(size_t newlength, size_t sizeelem, Array *p,
                                      size_t initsize, void *init)
in
{
    assert(sizeelem);
    assert(initsize);
    assert(initsize <= sizeelem);
    assert((sizeelem / initsize) * initsize == sizeelem);
    assert(!p.length || p.data);
}
body
{
    byte* newdata;

    debug
    {
        printf("_d_arraysetlength3(p = %p, sizeelem = %d, newlength = %d, initsize = %d)\n", p, sizeelem, newlength, initsize);
        if (p)
            printf("\tp.data = %p, p.length = %d\n", p.data, p.length);
    }

    if (newlength)
    {
        version (GNU)
        {
            // required to output the label;
            static char x = 0;
            if (x)
                goto Loverflow;
        }

        version (D_InlineAsm_X86)
        {
            size_t newsize = void;

            asm
            {
                mov     EAX,newlength   ;
                mul     EAX,sizeelem    ;
                mov     newsize,EAX     ;
                jc      Loverflow       ;
            }
        }
        else
        {
            size_t newsize = sizeelem * newlength;

            if (newsize / newlength != sizeelem)
                goto Loverflow;
        }
        //printf("newsize = %x, newlength = %x\n", newsize, newlength);

        size_t size = p.length * sizeelem;
        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                size_t cap = gc_sizeOf(p.data);

                if (cap <= newsize)
                {
                    newdata = cast(byte *)gc_malloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
                    newdata[0 .. size] = p.data[0 .. size];
                }
            }
        }
        else
        {
            newdata = cast(byte *)gc_malloc(newsize + 1, sizeelem < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        }

        if (newsize > size)
        {
            if (initsize == 1)
            {
                //printf("newdata = %p, size = %d, newsize = %d, *q = %d\n", newdata, size, newsize, *cast(byte*)q);
                newdata[size .. newsize] = *(cast(byte*)init);
            }
            else
            {
                for (size_t u = size; u < newsize; u += initsize)
                {
                    memcpy(newdata + u, init, initsize);
                }
            }
        }
    }
    else
    {
        newdata = p.data;
    }

    p.data = newdata;
    p.length = newlength;
    return newdata[0 .. newlength];

Loverflow:
    onOutOfMemoryError();
}


/**
 * Resize bit[] arrays.
 */
version (none)
{
    extern (C) bit[] _d_arraysetlengthb(size_t newlength, Array *p)
    {
        byte*  newdata;
        size_t newsize;

        debug printf("p = %p, newlength = %d\n", p, newlength);

        assert(!p.length || p.data);

        if (newlength)
        {
            newsize = ((newlength + 31) >> 5) * 4; // # bytes rounded up to uint
            if (p.length)
            {
                size_t size = ((p.length + 31) >> 5) * 4;

                newdata = p.data;
                if (newsize > size)
                {
                    size_t cap = gc_sizeOf(p.data);
                    if (cap <= newsize)
                    {
                        newdata = cast(byte *)gc_malloc(newsize + 1, BlkAttr.NO_SCAN);
                        newdata[0 .. size] = p.data[0 .. size];
                    }
                    newdata[size .. newsize] = 0;
                }
            }
            else
            {
                newdata = cast(byte *)gc_calloc(newsize + 1, BlkAttr.NO_SCAN);
            }
        }
        else
        {
            newdata = null;
        }

        p.data = newdata;
        p.length = newlength;
        return (cast(bit *)newdata)[0 .. newlength];
    }
}


/**
 * Append y[] to array x[].
 * size is size of each array element.
 */
extern (C) Array _d_arrayappend(Array *px, byte[] y, size_t  size)
{
    size_t cap       = gc_sizeOf(px.data);
    size_t length    = px.length;
    size_t newlength = length + y.length;

    if (newlength * size > cap)
    {
        cap = newCapacity(newlength, size);
        assert(cap >= newlength * size);
        void* newdata = gc_malloc(cap + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        memcpy(newdata, px.data, length * size);
        px.data = cast(byte*)newdata;
    }
    px.length = newlength;
    memcpy(px.data + length * size, y.ptr, y.length * size);
    return *px;
}


/**
 *
 */
version (none)
{
    extern (C) Array _d_arrayappendb(Array *px, bit[] y)
    {
        size_t cap       = gc_sizeOf(px.data);
        size_t length    = px.length;
        size_t newlength = length + y.length;
        size_t newsize   = (newlength + 7) / 8;

        if (newsize > cap)
        {
            cap = newCapacity(newsize, 1);
            assert(cap >= newsize);
            void* newdata = gc_malloc(cap + 1, BlkAttr.NO_SCAN);
            memcpy(newdata, px.data, (length + 7) / 8);
            px.data = cast(byte*)newdata;
        }
        px.length = newlength;
        if ((length & 7) == 0) // byte aligned, straightforward copy
            memcpy(px.data + length / 8, y, (y.length + 7) / 8);
        else
        {
            bit* x = cast(bit*)px.data;

            for (size_t u = 0; u < y.length; u++)
            {
                x[length + u] = y[u];
            }
        }
        return *px;
    }
}


/**
 *
 */
size_t newCapacity(size_t newlength, size_t size)
{
    version(none)
    {
        size_t newcap = newlength * size;
    }
    else
    {
        /*
         * Better version by Dave Fladebo:
         * This uses an inverse logorithmic algorithm to pre-allocate a bit more
         * space for larger arrays.
         * - Arrays smaller than 4096 bytes are left as-is, so for the most
         * common cases, memory allocation is 1 to 1. The small overhead added
         * doesn't effect small array perf. (it's virutally the same as
         * current).
         * - Larger arrays have some space pre-allocated.
         * - As the arrays grow, the relative pre-allocated space shrinks.
         * - The logorithmic algorithm allocates relatively more space for
         * mid-size arrays, making it very fast for medium arrays (for
         * mid-to-large arrays, this turns out to be quite a bit faster than the
         * equivalent realloc() code in C, on Linux at least. Small arrays are
         * just as fast as GCC).
         * - Perhaps most importantly, overall memory usage and stress on the GC
         * is decreased significantly for demanding environments.
         */
        size_t newcap = newlength * size;
        size_t newext = 0;

        if (newcap > 4096)
        {
            //double mult2 = 1.0 + (size / log10(pow(newcap * 2.0,2.0)));

            // redo above line using only integer math

            static int log2plus1(size_t c)
            {
                int i;

                if (c == 0)
                    i = -1;
                else
                    for (i = 1; c >>= 1; i++)
                    {
                    }
                return i;
            }

            /* The following setting for mult sets how much bigger
             * the new size will be over what is actually needed.
             * 100 means the same size, more means proportionally more.
             * More means faster but more memory consumption.
             */
            //long mult = 100 + (1000L * size) / (6 * log2plus1(newcap));
            long mult = 100 + (1000L * size) / log2plus1(newcap);

            // testing shows 1.02 for large arrays is about the point of diminishing return
            if (mult < 102)
                mult = 102;
            newext = cast(size_t)((newcap * mult) / 100);
            newext -= newext % size;
            debug printf("mult: %2.2f, alloc: %2.2f\n",mult/100.0,newext / cast(double)size);
        }
        newcap = newext > newcap ? newext : newcap;
        debug printf("newcap = %d, newlength = %d, size = %d\n", newcap, newlength, size);
    }
    return newcap;
}


/**
 *
 */
extern (C) byte[] _d_arrayappendcp(inout byte[] x, in size_t size, void *argp)
{
    size_t cap       = gc_sizeOf(x.ptr);
    size_t length    = x.length;
    size_t newlength = length + 1;

    assert(cap == 0 || length * size <= cap);

    debug printf("_d_arrayappendc(size = %d, ptr = %p, length = %d, cap = %d)\n", size, x.ptr, x.length, cap);

    if (newlength * size >= cap)
    {
        cap = newCapacity(newlength, size);
        assert(cap >= newlength * size);
        void* newdata = gc_malloc(cap + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
        memcpy(newdata, x.ptr, length * size);
        (cast(void**)(&x))[1] = newdata;
    }
    *cast(size_t *)&x = newlength;
    (cast(byte *)x)[length * size .. newlength * size] = (cast(byte*)argp)[0 .. size];
    assert((cast(size_t)x.ptr & 15) == 0);
    assert(gc_sizeOf(x.ptr) > x.length * size);
    return x;
}


/**
 *
 */
extern (C) byte[] _d_arraycat(byte[] x, byte[] y, size_t size)
out (result)
{
    debug printf("_d_arraycat(%d,%p ~ %d,%p size = %d => %d,%p)\n", x.length, x.ptr, y.length, y.ptr, size, result.length, result.ptr);

    assert(result.length == x.length + y.length);
    for (size_t i = 0; i < x.length * size; i++)
        assert((cast(byte*)result)[i] == (cast(byte*)x)[i]);
    for (size_t i = 0; i < y.length * size; i++)
        assert((cast(byte*)result)[x.length * size + i] == (cast(byte*)y)[i]);

    size_t cap = gc_sizeOf(result.ptr);
    assert(!cap || cap > result.length * size);
}
body
{
    version (none)
    {
        /* Cannot use this optimization because:
         *  char[] a, b;
         *  char c = 'a';
         *  b = a ~ c;
         *  c = 'b';
         * will change the contents of b.
         */
        if (!y.length)
            return x;
        if (!x.length)
            return y;
    }

    size_t xlen = x.length * size;
    size_t ylen = y.length * size;
    size_t len  = xlen + ylen;

    if (!len)
        return null;

    byte* p = cast(byte*)gc_malloc(len + 1, size < (void*).sizeof ? BlkAttr.NO_SCAN : 0);
    memcpy(p, x.ptr, xlen);
    memcpy(p + xlen, y.ptr, ylen);
    p[len] = 0;
    return p[0 .. x.length + y.length];
}


/**
 *
 */
version (none)
{
    extern (C) bit[] _d_arrayappendcb(inout bit[] x, bit b)
    {
        if (x.length & 7)
        {
            *cast(size_t *)&x = x.length + 1;
        }
        else
        {
            x.length = x.length + 1;
        }
        x[x.length - 1] = b;
        return x;
    }
}
