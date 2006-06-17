// D import file generated from 'core\memory.d'
module tango.core.memory;
private
{
    extern (C) 
{
    void gc_init();
}
    extern (C) 
{
    void gc_term();
}
    extern (C) 
{
    void gc_setFinalizer(void* p);
}
    extern (C) 
{
    void gc_enable();
}
    extern (C) 
{
    void gc_disable();
}
    extern (C) 
{
    void gc_collect();
}
    extern (C) 
{
    void* gc_malloc(size_t sz, bool df = false);
}
    extern (C) 
{
    void* gc_calloc(size_t sz, bool df = false);
}
    extern (C) 
{
    void* gc_realloc(void* p, size_t sz, bool df = false);
}
    extern (C) 
{
    void gc_free(void* p);
}
    extern (C) 
{
    size_t gc_sizeOf(void* p);
}
    extern (C) 
{
    size_t gc_capacityOf(void* p);
}
    extern (C) 
{
    void gc_addRoot(void* p);
}
    extern (C) 
{
    void gc_addRange(void* pbeg, void* pend);
}
    extern (C) 
{
    void gc_removeRoot(void* p);
}
    extern (C) 
{
    void gc_removeRange(void* pbeg, void* pend);
}
    extern (C) 
{
    void gc_pin(void* p);
}
    extern (C) 
{
    void gc_unpin(void* p);
}
}
struct GC
{
    void enable()
{
gc_enable();
}
    void disable()
{
gc_disable();
}
    void collect()
{
gc_collect();
}
    void* malloc(size_t sz, bool df = false)
{
return gc_malloc(sz,df);
}
    void* calloc(size_t sz, bool df = false)
{
return gc_calloc(sz,df);
}
    void* realloc(void* p, size_t sz, bool df = false)
{
return gc_realloc(p,sz,df);
}
    void free(void* p)
{
gc_free(p);
}
    size_t sizeOf(void* p)
{
return gc_sizeOf(p);
}
    size_t capacityOf(void* p)
{
return gc_capacityOf(p);
}
    void add(void* p)
{
gc_addRoot(p);
}
    void add(void* pbeg, void* pend)
{
gc_addRange(pbeg,pend);
}
    void remove(void* p)
{
gc_removeRoot(p);
}
    void remove(void* pbeg, void* pend)
{
gc_removeRange(pbeg,pend);
}
    void pin(void* p)
{
gc_pin(p);
}
    void unpin(void* p)
{
gc_unpin(p);
}
}
GC gc;
