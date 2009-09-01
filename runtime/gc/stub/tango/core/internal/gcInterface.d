/**
 * External interface exported by the gc (should move to common/*)
 */
module tango.core.internal.gcInterface;

// ------- gc interface, all gc need to expose the following functions --------
extern (C) void gc_init();
extern (C) void gc_term();

extern (C) void gc_enable();
extern (C) void gc_disable();
extern (C) void gc_collect();
extern (C) void gc_minimize();

extern (C) uint gc_getAttr( void* p );
extern (C) uint gc_setAttr( void* p, uint a );
extern (C) uint gc_clrAttr( void* p, uint a );

extern (C) void*  gc_malloc( size_t sz, uint ba = 0 );
extern (C) void*  gc_calloc( size_t sz, uint ba = 0 );
extern (C) void*  gc_realloc( void* p, size_t sz, uint ba = 0 );
extern (C) size_t gc_extend( void* p, size_t mx, size_t sz );
extern (C) size_t gc_reserve( size_t sz );
extern (C) void   gc_free( void* p );

extern (C) void*   gc_addrOf( void* p );
extern (C) size_t  gc_sizeOf( void* p );

struct BlkInfo_
{
    void*  base;
    size_t size;
    uint   attr;
}

extern (C) BlkInfo_ gc_query( void* p );

extern (C) void gc_addRoot( void* p );
extern (C) void gc_addRange( void* p, size_t sz );

extern (C) void gc_removeRoot( void* p );
extern (C) void gc_removeRange( void* p );

/// gc counter, it is assumed that if this & 1 is true then freeing is in progress
extern (C) size_t gc_counter();
/// waits that a collection & freeing cycle is finished
extern (C) void gc_finishGCRun();

extern (C) double gc_stats_opIndex(GCStats *gcStats,char[] c);
extern (C) bool gc_stats_opIn_r(GCStats *gcStats,char[] c);
extern (C) char[][] gc_stats_keys(GCStats *gcStats);
/// returns a stats structure that can be cached
/// statDetail is the amount of detail, 0 means everything, 1 means "cheap" information, 
/// the meaning of different values is gc dependent
extern (C) GCStats gc_stats(int statDetail);

/// NOTE: The content of this structure are gc dependent, but opIndex, opIn_r and keys
/// available for all gc
struct GCStats{
    void * d0; // put here a pointer if needed, should the GC be be precise...
    real[4] d1; // different types to guarantee correct alignment for stored types
    double d2;
    long d3;
    byte[64] d4;
    
    double opIndex(char[] c){
        return gc_stats_opIndex(this,c);
    }
    
    bool opIn_r(char[] c){
        return gc_stats_opIn_r(this,c);
    }
    
    char[][]keys(){
        return gc_stats_keys(this);
    }
}

