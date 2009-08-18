/+
 + The C interface exported by the runtime, this is the only interface that should be used
 + from outside the runtime
 +
 + Fawzi Mohamed
 +/
module rt.cInterface;

// rt.lifetime
struct Array
{
    size_t length;
    byte*  data;
}
struct Array2
{
    size_t length;
    void*  ptr;
}
//extern (C) Object _d_newclass(ClassInfo ci);
extern (C) Object _d_allocclass(ClassInfo ci);
extern (C) void _d_delinterface(void** p);
extern (C) ulong _d_newarrayT(TypeInfo ti, size_t length);
extern (C) ulong _d_newarrayiT(TypeInfo ti, size_t length);
extern (C) ulong _d_newarraymT(TypeInfo ti, int ndims, ...);
extern (C) ulong _d_newarraymiT(TypeInfo ti, int ndims, ...);
extern (C) void _d_delarray(Array *p);
extern (C) void _d_delmemory(void* *p);
extern (C) void _d_callinterfacefinalizer(void *p);
extern (C) void _d_callfinalizer(void* p);
alias bool function(Object) CollectHandler;
extern (C) void  rt_setCollectHandler(CollectHandler h);
extern (C) void rt_finalize(void* p, bool det = true);
extern (C) byte[] _d_arraysetlengthT(TypeInfo ti, size_t newlength, Array *p);
extern (C) byte[] _d_arraysetlengthiT(TypeInfo ti, size_t newlength, Array *p);
extern (C) long _d_arrayappendT(TypeInfo ti, Array *px, byte[] y);
extern (C) byte[] _d_arrayappendcT(TypeInfo ti, inout byte[] x, ...);
extern (C) byte[] _d_arraycatT(TypeInfo ti, byte[] x, byte[] y);
extern (C) byte[] _d_arraycatnT(TypeInfo ti, uint n, ...);
extern (C) void* _d_arrayliteralT(TypeInfo ti, size_t length, ...);
extern (C) long _adDupT(TypeInfo ti, Array2 a);
extern (C) void tango_abort();
extern (C) void tango_exit(int);

extern (C) size_t gc_counter();
extern (C) void gc_finishGCRun();

alias void delegate(Object) DEvent;
extern (C) void rt_attachDisposeEvent(Object h, DEvent e);
extern (C) bool rt_detachDisposeEvent(Object h, DEvent e);

// =========== rt.aaA ========
struct aaA
{
    aaA *left;
    aaA *right;
    hash_t hash;
    /* key   */
    /* value */
}

struct BB
{
    aaA*[] b;
    size_t nodes;       // total number of aaA nodes
    TypeInfo keyti;     // TODO: replace this with TypeInfo_AssociativeArray when available in _aaGet() 
}

/* This is the type actually seen by the programmer, although
 * it is completely opaque.
 */

// LDC doesn't pass structs in registers so no need to wrap it ...
alias BB* AA;

extern (C):
size_t _aaLen(AA aa);
void* _aaGet(AA* aa_arg, TypeInfo keyti, size_t valuesize, void* pkey);
void* _aaIn(AA aa, TypeInfo keyti, void *pkey);
void _aaDel(AA aa, TypeInfo keyti, void *pkey);
void[] _aaValues(AA aa, size_t keysize, size_t valuesize);
void* _aaRehash(AA* paa, TypeInfo keyti);
void[] _aaKeys(AA aa, size_t keysize);
extern (D) typedef int delegate(void *) dg_t;
int _aaApply(AA aa, size_t keysize, dg_t dg);
extern (D) typedef int delegate(void *, void *) dg2_t;
int _aaApply2(AA aa, size_t keysize, dg2_t dg);
int _aaEq(AA aa, AA ab, TypeInfo_AssociativeArray ti);
// =========== /aaA ========
