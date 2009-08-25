/**
 * External interface exported by the gc
 */
module tango.core.internal.gcInterface;
import tango.core.PerformanceTimers: realtimeClockFreq;

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

// ------- basicgc interface, other gc might differ -------

/// NOTE: The content of this structure are gc dependent, but opIndex, opIn and keys
/// are supposed to be available for all gc
struct GCStats
{
    size_t poolSize;        /// total size of pool
    size_t usedSize;        /// bytes allocated
    size_t freeBlocks;      /// number of blocks marked FREE
    size_t freelistSize;    /// total of memory on free lists
    size_t pageBlocks;      /// number of blocks marked PAGE
    size_t gcCounter;       /// number of GC phases (twice the number of gc collections)
    real totalPagesFreed;   /// total pages freed
    real totalMarkTime;     /// seconds spent in mark-phase
    real totalSweepTime;    /// seconds spent in sweep-phase
    ulong totalAllocTime;   /// total time spent in alloc and malloc,calloc,realloc,...free
    ulong nAlloc;           /// number of calls to allocation/free routines
    real opIndex(char[] prop){
        switch(prop){
        case "poolSize":
            return cast(real)poolSize;
        case "usedSize":
            return cast(real)usedSize;
        case "freeBlocks":
            return cast(real)freeBlocks;
        case "freelistSize":
            return cast(real)freelistSize;
        case "pageBlocks":
            return cast(real)pageBlocks;
        case "gcCounter":
            return 0.5*cast(real)gcCounter;
        case "totalPagesFreed":
            return totalPagesFreed;
        case "totalMarkTime":
            return totalMarkTime;
        case "totalSweepTime":
            return totalSweepTime;
        case "totalAllocTime":
            return cast(real)totalAllocTime/cast(real)realtimeClockFreq();
        case "nAlloc":
            return cast(real)nAlloc;
        default:
            throw new Exception("unsupported property",__FILE__,__LINE__);
        }
    }

    bool opIn(char[] c){
        return (c=="poolSize")||(c=="usedSize")||(c=="freeBlocks")||(c=="freelistSize")
            || (c=="pageBlocks")||(c=="gcCounter")||(c=="totalPagesFreed")||(c=="totalMarkTime")
            || (c=="totalSweepTime")||(c=="totalAllocTime")||(c=="nAlloc");
    }

    char[][]keys(){
        return ["poolSize"[],"usedSize","freeBlocks","freelistSize","pageBlocks",
        "gcCounter","totalPagesFreed","totalMarkTime","totalSweepTime","totalAllocTime",
        "nAlloc"];
    }
    
}

/// returns a stats structure that can be cached
extern (C) GCStats gc_stats();
