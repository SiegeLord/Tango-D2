/**
 * External interface exported by the gc
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

// ------- stubgc interface, other gc might differ -------

/// NOTE: The content of this structure are gc dependent, but opIndex, opIn and keys
/// are supposed to be available for all gc
struct GCStats{
    double opIndex(char[] c){
        throw new Exception("unsupported property",__FILE__,__LINE__);
    }
    
    bool opIn(char[] c){
        return false;
    }
    
    char[][]keys(){
        return null;
    }
}

/// returns a stats structure that can be cached
extern (C) GCStats gc_stats();
