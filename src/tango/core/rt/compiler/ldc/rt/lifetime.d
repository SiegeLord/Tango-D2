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
 * Authors:   Walter Bright, Sean Kelly, Tomas Lindquist Olsen
 */
module rt.lifetime;

//debug=PRINTF;
//debug=PRINTF2;

private
{
    import tango.stdc.string : memcpy, memset, memcmp;
    import tango.stdc.stdlib : free, malloc;
    debug(PRINTF) import tango.stdc.stdio : printf;
    else debug(PRINTF2) import tango.stdc.stdio : printf;
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

    extern (C) bool onCollectResource( Object o );
    extern (C) void onFinalizeError( ClassInfo c, Exception e );
    extern (C) void onOutOfMemoryError();

    extern (C) void _d_monitordelete(Object h, bool det = true);

    enum
    {
        PAGESIZE = 4096
    }

    alias bool function(Object) CollectHandler;
    CollectHandler collectHandler = null;

    size_t length_adjust(size_t sizeelem, size_t newlength)
    {
        size_t newsize = void;
        static if (size_t.sizeof < ulong.sizeof)
        {
            ulong s = cast(ulong)sizeelem * cast(ulong)newlength;
            if (s > size_t.max)
                onOutOfMemoryError();
            newsize = cast(size_t)s;
        }
        else
        {
            newsize = sizeelem * newlength;
            if (newsize / newlength != sizeelem)
                onOutOfMemoryError();
        }
        return newsize;
    }
}


/**
 *
 */
extern (C) Object _d_allocclass(ClassInfo ci)
{
    void* p;

    debug(PRINTF2) printf("_d_allocclass(ci = %p, %s)\n", ci, cast(char *)ci.name.ptr);
    /+
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
    +/
    {
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ci.pointermap;
        }
        p = gc_malloc(ci.init.length,
                      BlkAttr.FINALIZE | (ci.flags & 2 ? BlkAttr.NO_SCAN : 0),
                      pm);
        debug(PRINTF2) printf(" p = %p\n", p);
    }

    debug(PRINTF2)
    {
        printf("p = %p\n", p);
        printf("ci = %p, ci.init = %p, len = %d\n", ci, ci.init.ptr, ci.init.length);
        printf("vptr = %p\n", *cast(void**) ci.init.ptr);
        printf("vtbl[0] = %p\n", (*cast(void***) ci.init.ptr)[0]);
        printf("vtbl[1] = %p\n", (*cast(void***) ci.init.ptr)[1]);
        printf("init[0] = %p\n", (cast(uint**) ci.init.ptr)[0]);
        printf("init[1] = %p\n", (cast(uint**) ci.init.ptr)[1]);
        printf("init[2] = %p\n", (cast(uint**) ci.init.ptr)[2]);
        printf("init[3] = %p\n", (cast(uint**) ci.init.ptr)[3]);
        printf("init[4] = %p\n", (cast(uint**) ci.init.ptr)[4]);
    }

    // initialize it
    // ldc does this inline
    //(cast(byte*) p)[0 .. ci.init.length] = ci.init[];

    debug(PRINTF) printf("initialization done\n");
    return cast(Object) p;
}

/**
 *
 */
extern (C) void _d_delinterface(void* p)
{
    if (p)
    {
        Interface* pi = **cast(Interface ***)p;
        Object     o  = cast(Object)(p - pi.offset);

        _d_delclass(o);
        //*p = null;
    }
}

// used for deletion
private extern (D) alias void function(Object) fp_t;


/**
 *
 */
extern (C) void _d_delclass(Object p)
{
    if (p)
    {
        debug(PRINTF) printf("_d_delclass(%p)\n", p);

        ClassInfo **pc = cast(ClassInfo **)p;
        if (*pc)
        {
            ClassInfo c = **pc;

            rt_finalize(cast(void*) p);

            if (c.deallocator)
            {
                fp_t fp = cast(fp_t)c.deallocator;
                (*fp)(p); // call deallocator
                //*p = null;
                return;
            }
        }
        else
        {
            rt_finalize(cast(void*) p);
        }
        gc_free(cast(void*) p);
        //*p = null;
    }
}

/+

/**
 *
 */
struct Array
{
    size_t length;
    void*  data;
}

+/

/**
 * Allocate a new array of length elements.
 * ti is the type of the resulting array, or pointer to element.
 * The resulting array is initialized to 0
 */
extern (C) void* _d_newarrayT(TypeInfo ti, size_t length)
{
    void* p;
    auto size = ti.next.tsize();                // array element size

    debug(PRINTF) printf("_d_newarrayT(length = %u, size = %d)\n", length, size);
    if (length == 0 || size == 0)
        return null;

    size = length_adjust(size, length);

    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.next.pointermap();
    }
    p = gc_malloc(size + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0, pm);
    debug(PRINTF) printf(" p = %p\n", p);
    memset(p, 0, size);

    return p;
}

/**
 * As _d_newarrayT, but 
 * for when the array has a non-zero initializer.
 */
extern (C) void* _d_newarrayiT(TypeInfo ti, size_t length)
{
    void* result;
    auto size = ti.next.tsize();                // array element size

    debug(PRINTF) printf("_d_newarrayiT(length = %d, size = %d)\n", length, size);

    if (length == 0 || size == 0)
        result = null;
    else
    {
        auto initializer = ti.next.init();
        auto isize = initializer.length;
        auto q = initializer.ptr;

        size = length_adjust(size, length);

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
        result = p;
    }
    return result;
}

/**
 * As _d_newarrayT, but without initialization
 */
extern (C) void* _d_newarrayvT(TypeInfo ti, size_t length)
{
    void* p;
    auto size = ti.next.tsize();                // array element size

    debug(PRINTF) printf("_d_newarrayvT(length = %u, size = %d)\n", length, size);
    if (length == 0 || size == 0)
        return null;

    size = length_adjust(size, length);

    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.next.pointermap();
    }
    p = gc_malloc(size + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0, pm);
    debug(PRINTF) printf(" p = %p\n", p);
    return p;
}

/**
 * Allocate a new array of arrays of arrays of arrays ...
 * ti is the type of the resulting array.
 * ndims is the number of nested arrays.
 * dims it the array of dimensions, its size is ndims.
 * The resulting array is initialized to 0
 */
extern (C) void* _d_newarraymT(TypeInfo ti, int ndims, size_t* dims)
{
    void* result;

    debug(PRINTF) printf("_d_newarraymT(ndims = %d)\n", ndims);
    if (ndims == 0)
        result = null;
    else
    {
        static void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            debug(PRINTF) printf("foo(ti = %p, ti.next = %p, dim = %d, ndims = %d\n", ti, ti.next, dim, ndims);
            if (ndims == 1)
            {
                auto r = _d_newarrayT(ti, dim);
                return r[0 .. dim];
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

        result = foo(ti, dims, ndims).ptr;
        debug(PRINTF) printf("result = %p\n", result);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                printf("index %d: %d\n", i, *dims++);
            }
        }
    }
    return result;
}


/**
 * As _d_newarraymT, but 
 * for when the array has a non-zero initializer.
 */
extern (C) void* _d_newarraymiT(TypeInfo ti, int ndims, size_t* dims)
{
    void* result;

    debug(PRINTF) printf("_d_newarraymiT(ndims = %d)\n", ndims);
    if (ndims == 0)
        result = null;
    else
    {
        static void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            if (ndims == 1)
            {
                auto r = _d_newarrayiT(ti, dim);
                p = r[0 .. dim];
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

        result = foo(ti, dims, ndims).ptr;
        debug(PRINTF) printf("result = %p\n", result);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                printf("index %d: %d\n", i, *dims++);
                printf("init = %d\n", *dims++);
            }
        }
    }
    return result;
}

/**
 * As _d_newarraymT, but without initialization
 */
extern (C) void* _d_newarraymvT(TypeInfo ti, int ndims, size_t* dims)
{
    void* result;

    debug(PRINTF) printf("_d_newarraymvT(ndims = %d)\n", ndims);
    if (ndims == 0)
        result = null;
    else
    {
        static void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            debug(PRINTF) printf("foo(ti = %p, ti.next = %p, dim = %d, ndims = %d\n", ti, ti.next, dim, ndims);
            if (ndims == 1)
            {
                auto r = _d_newarrayvT(ti, dim);
                return r[0 .. dim];
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

        result = foo(ti, dims, ndims).ptr;
        debug(PRINTF) printf("result = %p\n", result);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                printf("index %d: %d\n", i, *dims++);
            }
        }
    }
    return result;
}

/+

/**
 *
 */
void* _d_allocmemory(size_t nbytes)
{
    return gc_malloc(nbytes);
}

+/

/**
 * for allocating a single POD value
 */
extern (C) void* _d_allocmemoryT(TypeInfo ti)
{
    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.pointermap();
    }
    return gc_malloc(ti.tsize(), !(ti.flags() & 1) ? BlkAttr.NO_SCAN : 0, pm);
}

/**
 *
 */
extern (C) void _d_delarray(size_t plength, void* pdata)
{
//     if (p)
//     {
// This assert on array consistency may fail with casts or in unions.
// This function still does something sensible even if plength && !pdata. 
//     assert(!plength || pdata);

        if (pdata)
            gc_free(pdata);
//         p.data = null;
//         p.length = 0;
//     }
}

/**
 *
 */
extern (C) void _d_delmemory(void* p)
{
    if (p)
    {
        gc_free(p);
        //*p = null;
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
                            debug(PRINTF) printf("calling dtor of %.*s\n", c.name.length, c.name.ptr);
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
extern (C) byte* _d_arraysetlengthT(TypeInfo ti, size_t newlength, size_t plength, byte* pdata)
in
{
    assert(ti);
// This assert on array consistency may fail with casts or in unions.
// This function still does something sensible even if plength && !pdata. 
//    assert(!plength || pdata);
}
body
{
    byte* newdata;
    size_t sizeelem = ti.next.tsize();

    debug(PRINTF)
    {
        printf("_d_arraysetlengthT(sizeelem = %d, newlength = %d)\n", sizeelem, newlength);
        printf("\tp.data = %p, p.length = %d\n", pdata, plength);
    }

    if (newlength)
    {
        size_t newsize = length_adjust(sizeelem, newlength);

        debug(PRINTF) printf("newsize = %x, newlength = %x\n", newsize, newlength);

        if (pdata)
        {
            newdata = pdata;
            if (newlength > plength)
            {
                size_t size = plength * sizeelem;
                auto   info = gc_query(pdata);

                if (info.size <= newsize || info.base != pdata)
                {
                    if (info.size >= PAGESIZE && info.base == pdata)
                    {   // Try to extend in-place
                        auto u = gc_extend(pdata, (newsize + 1) - info.size, (newsize + 1) - info.size);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    PointerMap pm;
                    version (D_HavePointerMap) {
                        pm = ti.next.pointermap();
                    }
                    newdata = cast(byte *)gc_malloc(newsize + 1,
                            !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                            pm);
                    newdata[0 .. size] = pdata[0 .. size];
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
        newdata = pdata;
    }

    return newdata;
}


/**
 * Resize arrays for non-zero initializers.
 *      p               pointer to array lvalue to be updated
 *      newlength       new .length property of array
 *      sizeelem        size of each element of array
 *      initsize        size of initializer
 *      ...             initializer
 */
extern (C) byte* _d_arraysetlengthiT(TypeInfo ti, size_t newlength, size_t plength, byte* pdata)
in
{
// This assert on array consistency may fail with casts or in unions.
// This function still does something sensible even if plength && !pdata. 
//    assert(!plength || pdata);
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
        printf("_d_arraysetlengthiT(sizeelem = %d, newlength = %d, initsize = %d)\n", sizeelem, newlength, initsize);
        printf("\tp.data = %p, p.length = %d\n", pdata, plength);
    }

    if (newlength)
    {
        size_t newsize = length_adjust(sizeelem, newlength);
        debug(PRINTF) printf("newsize = %x, newlength = %x\n", newsize, newlength);

        size_t size = plength * sizeelem;

        if (pdata)
        {
            newdata = pdata;
            if (newlength > plength)
            {
                auto info = gc_query(pdata);

                if (info.size <= newsize || info.base != pdata)
                {
                    if (info.size >= PAGESIZE && info.base == pdata)
                    {   // Try to extend in-place
                        auto u = gc_extend(pdata, (newsize + 1) - info.size, (newsize + 1) - info.size);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    PointerMap pm;
                    version (D_HavePointerMap) {
                        pm = ti.next.pointermap();
                    }
                    newdata = cast(byte *)gc_malloc(newsize + 1,
                            !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0,
                            pm);
                    newdata[0 .. size] = pdata[0 .. size];
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
        newdata = pdata;
    }

    return newdata;

Loverflow:
    onOutOfMemoryError();
    return null;
}

/+

/**
 * Append y[] to array x[].
 * size is size of each array element.
 */
extern (C) long _d_arrayappendT(TypeInfo ti, Array *px, byte[] y)
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
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        uint attr = !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        newdata = cast(byte *)gc_malloc(newCapacity(newlength, sizeelem) + 1, attr, pm);
        memcpy(newdata, px.data, length * sizeelem);
        px.data = newdata;
    }
  L1:
    px.length = newlength;
    memcpy(px.data + length * sizeelem, y.ptr, y.length * sizeelem);
    return *cast(long*)px;
}

+/

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
 * Appends a single element to an array.
 */
extern (C) byte[] _d_arrayappendcT(TypeInfo ti, void* array, void* element)
{
    auto x = cast(byte[]*)array;
    auto sizeelem = ti.next.tsize();            // array element size
    auto info = gc_query(x.ptr);
    auto length = x.length;
    auto newlength = length + 1;
    auto newsize = newlength * sizeelem;

    assert(info.size == 0 || length * sizeelem <= info.size);

    debug(PRINTF) printf("_d_arrayappendcT(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, info.size);

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
        debug(PRINTF) printf("_d_arrayappendcT(length = %d, newlength = %d, cap = %d, ti=%.*s)\n", length, newlength, info.size, ti.toString());
        auto newcap = newCapacity(newlength, sizeelem);
        assert(newcap >= newlength * sizeelem);
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        uint attr = !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0;
        newdata = cast(byte *)gc_malloc(newcap + 1, attr, pm);
        memcpy(newdata, x.ptr, length * sizeelem);
        (cast(void**)x)[1] = newdata;
    }
  L1:
    byte *argp = cast(byte *)element;

    *cast(size_t *)x = newlength;
    x.ptr[length * sizeelem .. newsize] = argp[0 .. sizeelem];
    assert((cast(size_t)x.ptr & 15) == 0);
    assert(gc_sizeOf(x.ptr) > x.length * sizeelem);
    return *x;
}


/**
 * Append dchar to char[]
 */
extern (C) char[] _d_arrayappendcd(ref char[] x, dchar c)
{
    const sizeelem = c.sizeof;            // array element size
    auto info = gc_query(x.ptr);
    auto length = x.length;

    // c could encode into from 1 to 4 characters
    int nchars;
    if (c <= 0x7F)
        nchars = 1;
    else if (c <= 0x7FF)
        nchars = 2;
    else if (c <= 0xFFFF)
        nchars = 3;
    else if (c <= 0x10FFFF)
        nchars = 4;
    else
    assert(0);  // invalid utf character - should we throw an exception instead?

    auto newlength = length + nchars;
    auto newsize = newlength * sizeelem;

    assert(info.size == 0 || length * sizeelem <= info.size);

    debug(PRINTF) printf("_d_arrayappendcd(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, info.size);

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
        debug(PRINTF) printf("_d_arrayappendcd(length = %d, newlength = %d, cap = %d)\n", length, newlength, info.size);
        auto newcap = newCapacity(newlength, sizeelem);
        assert(newcap >= newlength * sizeelem);
        newdata = cast(byte *)gc_malloc(newcap + 1, BlkAttr.NO_SCAN);
        memcpy(newdata, x.ptr, length * sizeelem);
        (cast(void**)(&x))[1] = newdata;
    }
  L1:
    *cast(size_t *)&x = newlength;
    char* ptr = &x.ptr[length];

    if (c <= 0x7F)
    {
        ptr[0] = cast(char) c;
    }
    else if (c <= 0x7FF)
    {
        ptr[0] = cast(char)(0xC0 | (c >> 6));
        ptr[1] = cast(char)(0x80 | (c & 0x3F));
    }
    else if (c <= 0xFFFF)
    {
        ptr[0] = cast(char)(0xE0 | (c >> 12));
        ptr[1] = cast(char)(0x80 | ((c >> 6) & 0x3F));
        ptr[2] = cast(char)(0x80 | (c & 0x3F));
    }
    else if (c <= 0x10FFFF)
    {
        ptr[0] = cast(char)(0xF0 | (c >> 18));
        ptr[1] = cast(char)(0x80 | ((c >> 12) & 0x3F));
        ptr[2] = cast(char)(0x80 | ((c >> 6) & 0x3F));
        ptr[3] = cast(char)(0x80 | (c & 0x3F));
    }
    else
    assert(0);

    assert((cast(size_t)x.ptr & 15) == 0);
    assert(gc_sizeOf(x.ptr) > x.length * sizeelem);
    return x;
}


/**
 * Append dchar to wchar[]
 */
extern (C) wchar[] _d_arrayappendwd(ref wchar[] x, dchar c)
{
    const sizeelem = c.sizeof;            // array element size
    auto info = gc_query(x.ptr);
    auto length = x.length;

    // c could encode into from 1 to 2 w characters
    int nchars;
    if (c <= 0xFFFF)
        nchars = 1;
    else
        nchars = 2;

    auto newlength = length + nchars;
    auto newsize = newlength * sizeelem;

    assert(info.size == 0 || length * sizeelem <= info.size);

    debug(PRINTF) printf("_d_arrayappendwd(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, info.size);

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
        debug(PRINTF) printf("_d_arrayappendwd(length = %d, newlength = %d, cap = %d)\n", length, newlength, info.size);
        auto newcap = newCapacity(newlength, sizeelem);
        assert(newcap >= newlength * sizeelem);
        newdata = cast(byte *)gc_malloc(newcap + 1, BlkAttr.NO_SCAN);
        memcpy(newdata, x.ptr, length * sizeelem);
        (cast(void**)(&x))[1] = newdata;
    }
  L1:
    *cast(size_t *)&x = newlength;
    wchar* ptr = &x.ptr[length];

    if (c <= 0xFFFF)
    {
        ptr[0] = cast(wchar) c;
    }
    else
    {
        ptr[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + 0xD800);
        ptr[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
    }

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
    auto size = ti.next.tsize(); // array element size

    p = cast(byte[]*)(&n + 1);

    for (i = 0; i < n; i++)
    {
        b = *p++;
        length += b.length;
    }
    if (!length)
        return null;

    PointerMap pm;
    version (D_HavePointerMap) {
        pm = ti.next.pointermap();
    }
    a = gc_malloc(length * size, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0, pm);
    p = cast(byte[]*)(&n + 1);

    uint j = 0;
    for (i = 0; i < n; i++)
    {
        b = *p++;
        if (b.length)
        {
            memcpy(a + j, b.ptr, b.length * size);
            j += b.length * size;
        }
    }

    byte[] result;
    *cast(size_t *)&result = length;       // jam length
    (cast(void **)&result)[1] = a;      // jam ptr
    return result;
}

/+

/**
 *
 */
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

+/


/**
 * Support for array.dup property.
 * The actual type is painted on the return value by the frontend
 * Given length is number of elements
 * Returned length is number of elements
 */


/**
 *
 */
extern (C) void[] _adDupT(TypeInfo ti, void[] a)
out (result)
{
    auto sizeelem = ti.next.tsize();            // array element size
    assert(memcmp(result.ptr, a.ptr, a.length * sizeelem) == 0);
}
body
{
    void* ptr;

    if (a.length)
    {
        auto sizeelem = ti.next.tsize();                // array element size
        auto size = a.length * sizeelem;
        PointerMap pm;
        version (D_HavePointerMap) {
            pm = ti.next.pointermap();
        }
        ptr = gc_malloc(size, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0, pm);
        memcpy(ptr, a.ptr, size);
    }
    return ptr[0 .. a.length];
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
