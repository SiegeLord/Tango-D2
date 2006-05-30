/*
 *  Copyright (C) 2005-2006 Sean Kelly
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

/**
 * The memory module provides an interface to the garbage collector and to
 * any other OS or API-level memory management facilities.
 *
 * Design Issues:
 *
 * Since memory management is often performed in performance-critical code,
 * it was important that the design of this module avoid any unnecessary
 * overhead.  For this reason, a number of possible designs (many of which
 * used an interface or abstract base class for GC interaction) were discarded
 * in favor of the current design.
 *
 * Future Directions:
 *
 * The GC code currently exposes certain OS-level functionality that may be
 * useful here, and which will likely be exposed in a future release.
 */
module tango.lang.memory;


private
{
    extern (C) void gc_init();
    extern (C) void gc_term();

    extern (C) void gc_setFinalizer( void *p );

    extern (C) void gc_enable();
    extern (C) void gc_disable();
    extern (C) void gc_collect();

    extern (C) void* gc_malloc( size_t sz, bool df = false );
    extern (C) void* gc_calloc( size_t sz, bool df = false );
    extern (C) void* gc_realloc( void* p, size_t sz, bool df = false );
    extern (C) void gc_free( void* p );

    extern (C) size_t gc_sizeOf( void* p );
    extern (C) size_t gc_capacityOf( void* p );

    extern (C) void gc_addRoot( void* p );
    extern (C) void gc_addRange( void* pbeg, void* pend );

    extern (C) void gc_removeRoot( void* p );
    extern (C) void gc_removeRange( void* pbeg, void* pend );

    extern (C) void gc_pin( void* p );
    extern (C) void gc_unpin( void* p );
}


/**
 * This struct encapsulates all garbage collection functionality for the D
 * programming language.  Currently, the garbage collector is decided at
 * link time, but this design could adapt to dynamic garbage collector
 * loading with few semantic changes.
 */
struct GC
{
    /**
     * Enables the garbage collector if collections have previously been
     * suspended by a call to disable.  This function is reentrant, and
     * must be called once for every call to disable before the garbage
     * collector is enabled.
     */
    void enable()
    {
        gc_enable();
    }


    /**
     * Disables the garbage collector.  This function is reentrant, but
     * enable must be called once for each call to disable.
     */
    void disable()
    {
        gc_disable();
    }


    /**
     * Begins a full collection.  While the meaning of this may change based
     * on the garbage collector implementation, typical behavior is to scan
     * all stack segments for roots, mark accessible memory blocks as alive,
     * and then to reclaim free space.  This action may need to suspend all
     * running threads for at least part of the collection process.
     */
    void collect()
    {
        gc_collect();
    }


    /**
     * Requests an aligned block of managed memory from the garbage collector.
     * This memory may be deleted at will with a call to free, or it may be
     * discarded and cleaned up automatically during a collection run.  If
     * allocation fails, this function will call onOutOfMemory which is
     * expected to throw an OutOfMemoryException.
     *
     * Params:
     *  sz = The desired allocation size in bytes.
     *  df = True if this memory block should be finalized.
     *
     * Returns:
     *  A reference to the allocated memory or null if insufficient memory
     *  is available.
     *
     * Throws:
     *  OutOfMemoryException on allocation failure.
     */
    void* malloc( size_t sz, bool df = false )
    {
        return gc_malloc( sz, df );
    }


    /**
     * Requests an aligned block of managed memory from the garbage collector,
     * which is initialized with all bits set to zero.  This memory may be
     * deleted at will with a call to free, or it may be discarded and cleaned
     * up automatically during a collection run.  If allocation fails, this
     * function will call onOutOfMemory which is expected to throw an
     * OutOfMemoryException.
     *
     * Params:
     *  sz = The desired allocation size in bytes.
     *  df = True if this memory block should be finalized.
     *
     * Returns:
     *  A reference to the allocated memory or null if insufficient memory
     *  is available.
     *
     * Throws:
     *  OutOfMemoryException on allocation failure.
     */
    void* calloc( size_t sz, bool df = false )
    {
        return gc_calloc( sz, df );
    }


    /**
     * If sz is zero, the memory referenced by p will be deallocated as if
     * by a call to free.  A new memory block of size sz will then be
     * allocated as if by a call to malloc, or the implementation may instead
     * resize the memory block in place.  The contents of the new memory block
     * will be the same as the contents of the old memory block, up to the
     * lesser of the new and old sizes.  Note that existing memory will only
     * be freed by realloc if sz is equal to zero.  The garbage collector is
     * otherwise expected to later reclaim the memory block if it is unused.
     * If allocation fails, this function will call onOutOfMemory which is
     * expected to throw an OutOfMemoryException.
     *
     * Params:
     *  p  = A pointer to the root of a valid memory block or to null.
     *  sz = The desired allocation size in bytes.
     *  df = True if this memory block should be finalized.
     *
     * Returns:
     *  A reference to the allocated memory on success or null if sz is
     *  zero.  On failure, the original value of p is returned.
     *
     * Throws:
     *  OutOfMemoryException on allocation failure.
     */
    void* realloc( void* p, size_t sz, bool df = false )
    {
        return gc_realloc( p, sz, df );
    }


    /**
     * Deallocates the memory references by p.  If p is null, no action
     * occurs.  If p references memory not originally allocated by this
     * garbage collector, or if it points to the interior of a memory block,
     * the result is undefined.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void free( void* p )
    {
        gc_free( p );
    }


    /**
     * Determines the allocated size of a memory block, equivalent to
     * the length property for arrays.  If p references memory not originally
     * allocated by this garbage collector, or if it points to the interior
     * of a memory block, zero will be returned.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *
     * Returns:
     *  The size in bytes of the memory block referenced by p or zero on error.
     */
    size_t sizeOf( void* p )
    {
        return gc_sizeOf( p );
    }


    /**
     * Determines the free space including and immediately following the memory
     * block referenced by p.  If p references memory not originally allocated
     * by this garbage collector, or if it points to the interior of a memory
     * block, zero will be returned.  The purpose of this function is to provide
     * a means to determine the maximum number of bytes for which a call to
     * realloc may resize the existing block in place.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     *
     * Returns:
     *  The size in bytes of the memory block referenced by p or zero on error.
     */
    size_t capacityOf( void* p )
    {
        return gc_capacityOf( p );
    }


    /**
     * Adds the memory block referenced by p to an internal list of roots to
     * be scanned during a collection.  If p is null, no operation is
     * performed.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void add( void* p )
    {
        gc_addRoot( p );
    }


    /**
     * Adds the memory range beginning with pbeg and ending immediately
     * before pend to to an internal list of memory blocks to be scanned
     * during a collection.  If pbeg and pend are null, no operation is
     * performed.
     *
     * Params:
     *  pbeg = A pointer to the a valid memory location or to null.
     *  pend = A pointer to one past the end of a valid memory block,
     *         or null if pbeg is null.
     */
    void add( void* pbeg, void* pend )
    {
        gc_addRange( pbeg, pend );
    }


    /**
     * Removes the memory block referenced by p from an internal list of roots
     * to be scanned during a collection.  If p is null, no operation is
     * performed.
     *
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void remove( void* p )
    {
        gc_removeRoot( p );
    }


    /**
     * Removes the memory block range beginning with pbeg and ending
     * immediately before pend from an internal list of roots to be
     * scanned during a collection.  If pbeg and pend were not previously
     * passed to the garbage collector by a call to add, the result is
     * undefined.  If pbeg and pend are null, no operation is performed.
     *
     * Params:
     *  pbeg = A pointer to the a valid memory location or to null.
     *  pend = A pointer to one past the end of a valid memory block,
     *         or null if pbeg is null.
     */
    void remove( void* pbeg, void* pend )
    {
        gc_removeRange( pbeg, pend );
    }


    /**
     * Ensures that the memory referenced by p will not be moved by the
     * garbage collector.  This function is reentrant, but unpin must be
     * called once for each call to pin.  If p is null, no operation is
     * performed.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void pin( void* p )
    {
        gc_pin( p );
    }


    /**
     * Allows the garbage collector to move the memory block referenced
     * by p during a collection, if pin has previously been called with
     * the supplied value of p as a parameter.  This function is reentrant,
     * and must be called once for every call to pin before the garbage
     * collector is free to move this block.
     *
     * Params:
     *  p = A pointer to the root of a valid memory block or to null.
     */
    void unpin( void* p )
    {
        gc_unpin( p );
    }
}


/**
 * All GC routines are accessed through this variable.  This is done to
 * follow the established D coding style guidelines and to reduce the
 * impact of future design changes.
 */
GC gc;