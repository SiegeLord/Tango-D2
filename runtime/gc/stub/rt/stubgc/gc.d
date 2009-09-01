/**
 * This module contains a minimal garbage collector implementation according to
 * Tango requirements.  This library is mostly intended to serve as an example,
 * but it is usable in applications which do not rely on a garbage collector
 * to clean up memory (ie. when dynamic array resizing is not used, and all
 * memory allocated with 'new' is freed deterministically with 'delete').
 *
 * Please note that block attribute data must be tracked, or at a minimum, the
 * FINALIZE bit must be tracked for any allocated memory block because calling
 * rt_finalize on a non-object block can result in an access violation.  In the
 * allocator below, this tracking is done via a leading uint bitmask.  A real
 * allocator may do better to store this data separately, similar to the basic
 * GC normally used by Tango.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 */
module rt.stubgc.gc;
private import tango.stdc.stdlib;

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

    extern (C) void thread_init();
    extern (C) void onOutOfMemoryError();
}

extern (C) void gc_init()
{
    // NOTE: The GC must initialize the thread library before its first
    //       collection, and always before returning from gc_init().
    thread_init();
}

extern (C) void gc_term(){}

extern (C) void gc_enable(){}

extern (C) void gc_disable(){}

extern (C) void gc_collect(){}

extern (C) void gc_minimize(){}

extern (C) uint gc_getAttr( void* p )
{
    return 0;
}

extern (C) uint gc_setAttr( void* p, uint a )
{
    return 0;
}

extern (C) uint gc_clrAttr( void* p, uint a )
{
    return 0;
}

extern (C) void* gc_malloc( size_t sz, uint ba = 0 )
{
    void* p = malloc( sz );

    if( sz && p is null )
        onOutOfMemoryError();
    return p;
}

extern (C) void* gc_calloc( size_t sz, uint ba = 0 )
{
    void* p = calloc( 1, sz );

    if( sz && p is null )
        onOutOfMemoryError();
    return p;
}

extern (C) void* gc_realloc( void* p, size_t sz, uint ba = 0 )
{
    p = realloc( p, sz );

    if( sz && p is null )
        onOutOfMemoryError();
    return p;
}

extern (C) size_t gc_extend( void* p, size_t mx, size_t sz )
{
    return 0;
}

extern (C) size_t gc_reserve( size_t sz )
{
    return 0;
}

extern (C) void gc_free( void* p )
{
    free( p );
}

extern (C) void* gc_addrOf( void* p )
{
    return null;
}

extern (C) size_t gc_sizeOf( void* p )
{
    return 0;
}

extern (C) BlkInfo gc_query( void* p )
{
    return BlkInfo.init;
}

extern (C) void gc_addRoot( void* p ){}

extern (C) void gc_addRange( void* p, size_t sz ){}

extern (C) void gc_removeRoot( void *p ){}

extern (C) void gc_removeRange( void *p ){}

extern (C) size_t gc_counter(){
    return cast(size_t)0;
}

extern (C) void gc_finishGCRun(){}

/// gc counter, it is assumed that if this & 1 is true then freeing is in progress
extern (C) size_t gc_counter();
/// waits that a collection & freeing cycle is finished
extern (C) void gc_finishGCRun();

/// returns a stats structure that can be cached
extern (C) GCStats gc_stats(int statDetail){
    GCStats n;
    return n;
}

extern (C) double gc_stats_opIndex(GCStats *gcStats,char[] c){
    throw new Exception("unknown key "~c,__FILE__,__LINE);
}
extern (C) bool gc_stats_opIn_r(GCStats *gcStats,char[] c){
    return false;
}
extern (C) char[][] gc_stats_keys(GCStats *gcStats){
    return null;
}
