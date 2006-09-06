version (GC_Use_Alloc_MMap)
{
    private import tango.stdc.posix.sys.mman;
    void *os_mem_map(uint nbytes)
    {   void *p;
        p = mmap(null, nbytes, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        return (p == MAP_FAILED) ? null : p;
    }
    int os_mem_commit(void *base, uint offset, uint nbytes)
    {
        return 0;
    }

    int os_mem_decommit(void *base, uint offset, uint nbytes)
    {
        return 0;
    }

    int os_mem_unmap(void *base, uint nbytes)
    {
        return munmap(base, nbytes);
    }
}
else version (GC_Use_Alloc_Valloc)
{
    extern (C) void * valloc(size_t);
    void *os_mem_map(uint nbytes) { return valloc(nbytes); }
    int os_mem_commit(void *base, uint offset, uint nbytes) { return 0; }
    int os_mem_decommit(void *base, uint offset, uint nbytes) { return 0; }
    int os_mem_unmap(void *base, uint nbytes) { free(base); return 0; }
}
else version (GC_Use_Alloc_Malloc)
{
    /* Assumes malloc granularity is at least (void *).sizeof.  If
       (req_size + PAGESIZE) is allocated, and the pointer is rounded
       up to PAGESIZE alignment, there will be space for a void* at the
       end after PAGESIZE bytes used by the GC. */

    private import gcx; // for PAGESIZE
    private import tango.stdc.stdlib; // for malloc, free

    const uint PAGE_MASK = PAGESIZE - 1;

    void *os_mem_map(uint nbytes)
    {   byte * p, q;
        p = cast(byte *) malloc(nbytes + PAGESIZE);
        q = p + ((PAGESIZE - ((cast(size_t) p & PAGE_MASK))) & PAGE_MASK);
        * cast(void**)(q + nbytes) = p;
        return q;
    }
    int os_mem_commit(void *base, uint offset, uint nbytes)
    {
        return 0;
    }

    int os_mem_decommit(void *base, uint offset, uint nbytes)
    {
        return 0;
    }

    int os_mem_unmap(void *base, uint nbytes)
    {
        free( * cast(void**)( cast(byte*) base + nbytes ) );
        return 0;
    }
}
else version (GC_Use_Alloc_Fixed_Heap)
{
    // TODO
    static assert(0);
}
else
{
    static assert(0);
}