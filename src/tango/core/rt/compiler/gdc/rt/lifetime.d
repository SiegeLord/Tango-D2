/**
 * This module contains all functions related to an object's lifetime:
 * allocation, resizing, deallocation, and finalization.
 *
 * Copyright: Copyright (C) 2004-2007 Digital Mars, www.digitalmars.com.
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
module rt.compiler.gdc.rt.lifetime;


private
{
    import tango.stdc.stdlib;
    import tango.stdc.string;
    import tango.stdc.stdarg;
    debug(PRINTF) import tango.stdc.stdio;
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

    struct BlkInfo
    {
        void*  base;
        size_t size;
        uint   attr;
    }

    extern (C) uint gc_getAttr( void* p );
    extern (C) uint gc_setAttr( void* p, uint a );
    extern (C) uint gc_clrAttr( void* p, uint a );

    extern (C) void*  gc_malloc( size_t sz, uint ba = 0, PointerMap bitMask = PointerMap.init);
    extern (C) void*  gc_calloc( size_t sz, uint ba = 0, PointerMap bitMask = PointerMap.init);
    extern (C) size_t gc_extend( void* p, size_t mx, size_t sz );
    extern (C) void   gc_free( void* p );

    extern (C) void*   gc_addrOf( void* p );
    extern (C) size_t  gc_sizeOf( void* p );
    extern (C) BlkInfo gc_query( void* p );

    extern (C) void onFinalizeError( ClassInfo c, Exception e );
    extern (C) void onOutOfMemoryError();

    extern (C) void _d_monitordelete(Object h, bool det = true);

    enum
    {
        PAGESIZE = 4096
    }
    alias bool function(Object) CollectHandler;
    CollectHandler collectHandler = null;
}


/**
 *
 */
extern (C) Object _d_newclass(ClassInfo ci)
{
    void* p;

    debug(PRINTF) printf("_d_newclass(ci = %p, %s)\n", ci, cast(char *)ci.name);
    if (ci.flags & 1) // if COM object
    {   /* COM objects are not garbage collected, they are reference counted
         * using AddRef() and Release().  They get free'd by C's free()
         * function called by Release() when Release()'s reference count goes
         * to zero.
	 */
        p = tango.stdc.stdlib.malloc(ci.init.length);
        if (!p)
            onOutOfMemoryError();
    }
    else
    {
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ci.pointermap;
        }
        p = gc_malloc(ci.init.length,
                      BlkAttr.FINALIZE | (ci.flags & 2 ? BlkAttr.NO_SCAN : 0),
                      pm);
        debug(PRINTF) printf(" p = %p\n", p);
    }

    debug(PRINTF)
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

    debug(PRINTF) printf("initialization done\n");
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
        debug(PRINTF) printf("_d_delclass(%p)\n", *p);

        ClassInfo **pc = cast(ClassInfo **)*p;
        if (*pc)
        {
            ClassInfo c = **pc;

            rt_finalize(cast(void*) *p);

            if (c.deallocator)
            {
                fp_t fp = cast(fp_t)c.deallocator;
                (*fp)(*p); // call deallocator
                *p = null;
                return;
            }
        }
        else
        {
            rt_finalize(cast(void*) *p);
        }
        gc_free(cast(void*) *p);
        *p = null;
    }
}


/**
 * Allocate a new array of length elements.
 * ti is the type of the resulting array, or pointer to element.
 * (For when the array is initialized to 0)
 */
extern (C) Array _d_newarrayT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize();                // array element size

    debug(PRINTF) printf("_d_newarrayT(length = x%x, size = %d)\n", length, size);
    if (length == 0 || size == 0)
        {}
    else
    {
        result.length = length;
        /*version (D_InlineAsm_X86)
        {
            asm
            {
                mov     EAX,size        ;
                mul     EAX,length      ;
                mov     size,EAX        ;
                jc      Loverflow       ;
            }
        }
        else*/
            size *= length;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        result.data = cast(byte*) gc_malloc(size + 1,
                !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                pm);
        memset(result.data, 0, size);
    }
    return result;

Loverflow:
    onOutOfMemoryError();
}


/**
 * For when the array has a non-zero initializer.
 */
extern (C) Array _d_newarrayiT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize(); // array element size

    debug(PRINTF) printf("_d_newarrayiT(length = %d, size = %d)\n", length, size);

    if (length == 0 || size == 0)
        {}
    else
    {
        auto initializer = ti.next.init();
        auto isize = initializer.length;
        auto q = initializer.ptr;
        /*version (D_InlineAsm_X86)
        {
            asm
            {
                mov     EAX,size        ;
                mul     EAX,length      ;
                mov     size,EAX        ;
                jc      Loverflow       ;
            }
        }
        else*/
            size *= length;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        auto p = gc_malloc(size + 1,
                !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                pm);
        debug(PRINTF) printf(" p = %p\n", p);
        if (isize == 1)
            memset(p, *cast(ubyte*)q, size);
        else if (isize == int.sizeof)
        {
            int init = *cast(int*)q;
            size /= int.sizeof;
            for (size_t u = 0; u < size; u++)
            {
                (cast(int*)p)[u] = init;
            }
        }
        else
        {
            for (size_t u = 0; u < size; u += isize)
            {
                memcpy(p + u, q, isize);
            }
        }
        result.length = length;
        result.data = cast(byte*) p;
    }
    return result;

Loverflow:
    onOutOfMemoryError();
}


/**
 *
 */
extern (C) void[] _d_newarraymTp(TypeInfo ti, int ndims, size_t* pdim)
{
    void[] result = void;

    debug(PRINTF) printf("_d_newarraymTp(ndims = %d)\n", ndims);
    if (ndims == 0)
        result = null;
    else
    {

        void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            debug(PRINTF) printf("foo(ti = %p, ti.next = %p, dim = %d, ndims = %d\n", ti, ti.next, dim, ndims);
            if (ndims == 1)
            {
                auto r = _d_newarrayT(ti, dim);
                p = *cast(void[]*)(&r);
            }
            else
            {
                p = gc_malloc(dim * (void[]).sizeof + 1)[0 .. dim];
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(ti.next, pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        result = foo(ti, pdim, ndims);
        debug(PRINTF) printf("result = %llx\n", result);

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
extern (C) void[] _d_newarraymiTp(TypeInfo ti, int ndims, size_t* pdim)
{
    void[] result = void;

    debug(PRINTF) printf("_d_newarraymiTp(ndims = %d)\n", ndims);
    if (ndims == 0)
        result = null;
    else
    {

        void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            if (ndims == 1)
            {
                auto r = _d_newarrayiT(ti, dim);
                p = *cast(void[]*)(&r);
            }
            else
            {
                p = gc_malloc(dim * (void[]).sizeof + 1)[0 .. dim];
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(ti.next, pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        result = foo(ti, pdim, ndims);
        debug(PRINTF) printf("result = %llx\n", result);

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
struct Array
{
    size_t length;
    byte*  data;
}


/**
 *
 */
void* _d_allocmemory(size_t nbytes)
{
    return gc_malloc(nbytes);
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
extern (C) void _d_callinterfacefinalizer(void *p)
{
    if (p)
    {
        Interface *pi = **cast(Interface ***)p;
        Object o = cast(Object)(p - pi.offset);
        rt_finalize(cast(void*)o);
    }
}


/**
 *
 */
extern (C) void _d_callfinalizer(void* p)
{
    rt_finalize( p );
}


/**
 *
 */
extern (C) void  rt_setCollectHandler(CollectHandler h)
{
    collectHandler = h;
}


/**
 *
 */
extern (C) void rt_finalize(void* p, bool det = true)
{
    debug(PRINTF) printf("rt_finalize(p = %p)\n", p);

    if (p) // not necessary if called from gc
    {
        if (det)
           (cast(Object)p).dispose();

        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;

            try
            {
                if (det || collectHandler is null || collectHandler(cast(Object)p))
                {
                    do
                    {
                        if (c.destructor !is null)
                        {
                            void delegate() dg;
                            dg.ptr = p;
                            dg.funcptr = cast(void function()) c.destructor;
                            dg(); // call destructor
                        }
                        c = c.base;
                    } while (c);
                }
                if ((cast(void**)p)[1]) // if monitor is not null
                    _d_monitordelete(cast(Object)p, det);
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
extern (C) byte[] _d_arraysetlengthT(TypeInfo ti, size_t newlength, Array *p)
in
{
    assert(ti);
    assert(!p.length || p.data);
}
body
{
    byte* newdata;
    size_t sizeelem = ti.next.tsize();

    debug(PRINTF)
    {
        printf("_d_arraysetlengthT(p = %p, sizeelem = %d, newlength = %d)\n", p, sizeelem, newlength);
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

        debug(PRINTF) printf("newsize = %x, newlength = %x\n", newsize, newlength);

        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                size_t size = p.length * sizeelem;
                auto   info = gc_query(p.data);

                if (info.size <= newsize || info.base != p.data)
                {
                    if (info.size >= PAGESIZE && info.base == p.data)
                    {   // Try to extend in-place
                        auto u = gc_extend(p.data, (newsize + 1) - info.size, (newsize + 1) - info.size);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    PointerMap pm;
                    version (D_HavePointerMap) {
                        pm = ti.next.pointermap();
                    }
                    newdata = cast(byte *)gc_malloc(newsize + 1, info.attr, pm);
                    newdata[0 .. size] = p.data[0 .. size];
                }
             L1:
                newdata[size .. newsize] = 0;
            }
        }
        else
        {
            PointerMap pm;
            version (D_HavePointerMap) {
                pm = ti.next.pointermap();
            }
            newdata = cast(byte *)gc_calloc(newsize + 1,
                    !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                    pm);
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
extern (C) byte[] _d_arraysetlengthiT(TypeInfo ti, size_t newlength, Array *p)
in
{
    assert(!p.length || p.data);
}
body
{
    byte* newdata;
    size_t sizeelem = ti.next.tsize();
    void[] initializer = ti.next.init();
    size_t initsize = initializer.length;

    assert(sizeelem);
    assert(initsize);
    assert(initsize <= sizeelem);
    assert((sizeelem / initsize) * initsize == sizeelem);

    debug(PRINTF)
    {
        printf("_d_arraysetlengthiT(p = %p, sizeelem = %d, newlength = %d, initsize = %d)\n", p, sizeelem, newlength, initsize);
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
        debug(PRINTF) printf("newsize = %x, newlength = %x\n", newsize, newlength);

        size_t size = p.length * sizeelem;
        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                auto info = gc_query(p.data);

                if (info.size <= newsize || info.base != p.data)
                {
                    if (info.size >= PAGESIZE && info.base == p.data)
                    {   // Try to extend in-place
                        auto u = gc_extend(p.data, (newsize + 1) - info.size, (newsize + 1) - info.size);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    PointerMap pm;
                    version (D_HavePointerMap) {
                        pm = ti.next.pointermap();
                    }
                    newdata = cast(byte *)gc_malloc(newsize + 1, info.attr, pm);
                    newdata[0 .. size] = p.data[0 .. size];
                L1: ;
                }
            }
        }
        else
        {
            PointerMap pm;
            version (D_HavePointerMap) {
                pm = ti.next.pointermap();
            }
            newdata = cast(byte *)gc_malloc(newsize + 1,
                    !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                    pm);
        }

        auto q = initializer.ptr; // pointer to initializer

        if (newsize > size)
        {
            if (initsize == 1)
            {
                debug(PRINTF) printf("newdata = %p, size = %d, newsize = %d, *q = %d\n", newdata, size, newsize, *cast(byte*)q);
                newdata[size .. newsize] = *(cast(byte*)q);
            }
            else
            {
                for (size_t u = size; u < newsize; u += initsize)
                {
                    memcpy(newdata + u, q, initsize);
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
 * Append y[] to array x[].
 * size is size of each array element.
 */
extern (C) Array _d_arrayappendT(TypeInfo ti, Array *px, byte[] y)
{
    auto sizeelem = ti.next.tsize();            // array element size
    auto info = gc_query(px.data);
    auto length = px.length;
    auto newlength = length + y.length;
    auto newsize = newlength * sizeelem;

    if (info.size < newsize || info.base != px.data)
    {   byte* newdata;

        if (info.size >= PAGESIZE && info.base == px.data)
        {   // Try to extend in-place
            auto u = gc_extend(px.data, (newsize + 1) - info.size, (newsize + 1) - info.size);
            if (u)
            {
                goto L1;
            }
        }
        uint attr = info.attr;
        // If this is the first allocation, set the NO_SCAN attribute appropriately
        if (info.base is null && ti.next.flags() == 0)
            attr = BlkAttr.NO_SCAN;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        newdata = cast(byte *)gc_malloc(newCapacity(newlength, sizeelem) + 1,
                attr, pm);
        memcpy(newdata, px.data, length * sizeelem);
        px.data = newdata;
    }
  L1:
    px.length = newlength;
    memcpy(px.data + length * sizeelem, y.ptr, y.length * sizeelem);
    return *px;
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
         * Better version by Fawzi, inspired by the one of Dave Fladebo:
         * This uses an inverse logorithmic algorithm to pre-allocate a bit more
         * space for larger arrays.
         * - Arrays smaller than PAGESIZE bytes are left as-is, so for the most
         * common cases, memory allocation is 1 to 1. The small overhead added
         * doesn't affect small array perf. (it's virtually the same as
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

        if (newcap > PAGESIZE)
        {
            const size_t b=0; // flatness factor, how fast the extra space decreases with array size
            const size_t a=100; // allocate at most a% of the requested size as extra space (rounding will change this)
            const size_t minBits=1; // minimum bit size
            

            static size_t log2plusB(size_t c)
            {
                // could use the bsr bit op
                size_t i=b+1;
                while(c >>= 1){
                    ++i;
                }
                return i;
            }
            long mult = 100 + a*(minBits+b) / log2plusB(newlength);

            newext = cast(size_t)((newcap * mult) / 100);
            newext += size-(newext % size); // round up
            debug(PRINTF) printf("mult: %2.2f, alloc: %2.2f\n",mult/100.0,newext / cast(double)size);
        }
        newcap = newext > newcap ? newext : newcap; // just to handle overflows
        debug(PRINTF) printf("newcap = %d, newlength = %d, size = %d\n", newcap, newlength, size);
    }
    return newcap;
}


/**
 *
 */
extern (C) byte[] _d_arrayappendcTp(TypeInfo ti, ref byte[] x, void *argp)
{
    auto sizeelem = ti.next.tsize();            // array element size
    auto info = gc_query(x.ptr);
    auto length = x.length;
    auto newlength = length + 1;
    auto newsize = newlength * sizeelem;

    assert(info.size == 0 || length * sizeelem <= info.size);

    debug(PRINTF) printf("_d_arrayappendcTp(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, info.size);

    if (info.size <= newsize || info.base != x.ptr)
    {   byte* newdata;

        if (info.size >= PAGESIZE && info.base == x.ptr)
        {   // Try to extend in-place
            auto u = gc_extend(x.ptr, (newsize + 1) - info.size, (newsize + 1) - info.size);
            if (u)
            {
                goto L1;
            }
        }
        debug(PRINTF) printf("_d_arrayappendcTp(length = %d, newlength = %d, cap = %d)\n", length, newlength, info.size);
        auto newcap = newCapacity(newlength, sizeelem);
        assert(newcap >= newlength * sizeelem);
        uint attr = info.attr;
        // If this is the first allocation, set the NO_SCAN attribute appropriately
        if (info.base is null && ti.next.flags() == 0)
            attr = BlkAttr.NO_SCAN;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        newdata = cast(byte *)gc_malloc(newcap + 1, attr, pm);
        memcpy(newdata, x.ptr, length * sizeelem);
        (cast(void**)(&x))[1] = newdata;
    }
  L1:
    *cast(size_t *)&x = newlength;
    x.ptr[length * sizeelem .. newsize] = (cast(byte*)argp)[0 .. sizeelem];
    assert((cast(size_t)x.ptr & 15) == 0);
    assert(gc_sizeOf(x.ptr) > x.length * sizeelem);
    return x;
}


/**
 *
 */
extern (C) byte[] _d_arraycatT(TypeInfo ti, byte[] x, byte[] y)
out (result)
{
    auto sizeelem = ti.next.tsize();            // array element size
    debug(PRINTF) printf("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d => %d,%p)\n", x.length, x.ptr, y.length, y.ptr, sizeelem, result.length, result.ptr);
    assert(result.length == x.length + y.length);
    for (size_t i = 0; i < x.length * sizeelem; i++)
        assert((cast(byte*)result)[i] == (cast(byte*)x)[i]);
    for (size_t i = 0; i < y.length * sizeelem; i++)
        assert((cast(byte*)result)[x.length * sizeelem + i] == (cast(byte*)y)[i]);

    size_t cap = gc_sizeOf(result.ptr);
    assert(!cap || cap > result.length * sizeelem);
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

    debug(PRINTF) printf("_d_arraycatT(%d,%p ~ %d,%p)\n", x.length, x.ptr, y.length, y.ptr);
    auto sizeelem = ti.next.tsize();            // array element size
    debug(PRINTF) printf("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d)\n", x.length, x.ptr, y.length, y.ptr, sizeelem);
    size_t xlen = x.length * sizeelem;
    size_t ylen = y.length * sizeelem;
    size_t len  = xlen + ylen;

    if (!len)
        return null;

    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.next.pointermap();
    }
    byte* p = cast(byte*)gc_malloc(len + 1,
            !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
            pm);
    memcpy(p, x.ptr, xlen);
    memcpy(p + xlen, y.ptr, ylen);
    p[len] = 0;
    return p[0 .. x.length + y.length];
}


/**
 *
 */
extern (C) byte[] _d_arraycatnT(TypeInfo ti, uint n, ...)
{   void* a;
    size_t length;
    byte[]* p;
    uint i;
    byte[] b;
    va_list va;
    auto size = ti.next.tsize(); // array element size

    va_start!(typeof(n))(va, n);

    for (i = 0; i < n; i++)
    {
        b = va_arg!(typeof(b))(va);
        length += b.length;
    }
    if (!length)
        return null;

    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.next.pointermap();
    }
    a = gc_malloc(length * size, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
            pm);
    va_start!(typeof(n))(va, n);

    uint j = 0;
    for (i = 0; i < n; i++)
    {
        b = va_arg!(typeof(b))(va);
        if (b.length)
        {
            memcpy(a + j, b.ptr, b.length * size);
            j += b.length * size;
        }
    }

    return (cast(byte*)a)[0..length];
}


/**
 *
 */
version (GNU) { } else
extern (C) void* _d_arrayliteralT(TypeInfo ti, size_t length, ...)
{
    auto sizeelem = ti.next.tsize();            // array element size
    void* result;

    debug(PRINTF) printf("_d_arrayliteralT(sizeelem = %d, length = %d)\n", sizeelem, length);
    if (length == 0 || sizeelem == 0)
        result = null;
    else
    {
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        result = gc_malloc(length * sizeelem,
                !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                pm);

        va_list q;
        va_start!(size_t)(q, length);

        size_t stacksize = (sizeelem + int.sizeof - 1) & ~(int.sizeof - 1);

        if (stacksize == sizeelem)
        {
            memcpy(result, q, length * sizeelem);
        }
        else
        {
            for (size_t i = 0; i < length; i++)
            {
                memcpy(result + i * sizeelem, q, sizeelem);
                q += stacksize;
            }
        }

        va_end(q);
    }
    return result;
}


/**
 * Support for array.dup property.
 */
struct Array2
{
    size_t length;
    void*  ptr;
}


/**
 *
 */
extern (C) Array2 _adDupT(TypeInfo ti, Array2 a)
out (result)
{
    auto sizeelem = ti.next.tsize();            // array element size
    assert(memcmp((*cast(Array2*)&result).ptr, a.ptr, a.length * sizeelem) == 0);
}
body
{
    Array2 r;

    if (a.length)
    {
        auto sizeelem = ti.next.tsize();                // array element size
        auto size = a.length * sizeelem;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        r.ptr = gc_malloc(size, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                pm);
        r.length = a.length;
        memcpy(r.ptr, a.ptr, size);
    }
    return r;
}


unittest
{
    int[] a;
    int[] b;
    int i;

    a = new int[3];
    a[0] = 1; a[1] = 2; a[2] = 3;
    b = a.dup;
    assert(b.length == 3);
    for (i = 0; i < 3; i++)
        assert(b[i] == i + 1);
}
