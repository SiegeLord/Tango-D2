/**
 * The Atomic module is intended to provide some basic support for the so called lock-free
 * concurrent programming.
 * The current design replaces the previous Atomic module by Sean and is inspired
 * partly by the llvm atomic operations, and Sean's version
 * 
 * If no atomic ops are available an (inefficent) fallback solution is provided
 * For classes atomic access means atomic access to their *address* not their content
 * 
 * If you want unique counters or flags to communicate in multithreading settings
 * look at tango.core.sync.Counter that provides them in a better way and handles
 * better the absence of atomic ops.
 *
 * Copyright: Copyright (C) 2008-2010 the blip developer group
 * License:   BSD style: $(LICENSE)
 * Author:    Fawzi Mohamed
 */

module tango.core.sync.Atomic;

version( LDC )
{
    import ldc.intrinsics;
}

private {
    // from tango.core.traits:
    /**
     * Evaluates to true if T is a signed or unsigned integer type.
     */
    template isIntegerType( T )
    {
        const bool isIntegerType = isSignedIntegerType!(T) ||
                                   isUnsignedIntegerType!(T);
    }
    /**
     * Evaluates to true if T is a pointer type.
     */
    template isPointerOrClass(T)
    {
        const isPointerOrClass = is(T==class);
    }

    template isPointerOrClass(T : T*)
    {
            const isPointerOrClass = true;
    }
    /**
     * Evaluates to true if T is a signed integer type.
     */
    template isSignedIntegerType( T )
    {
        const bool isSignedIntegerType = is( T == byte )  ||
                                         is( T == short ) ||
                                         is( T == int )   ||
                                         is( T == long )/+||
                                         is( T == cent  )+/;
    }
    /**
     * Evaluates to true if T is an unsigned integer type.
     */
    template isUnsignedIntegerType( T )
    {
        const bool isUnsignedIntegerType = is( T == ubyte )  ||
                                           is( T == ushort ) ||
                                           is( T == uint )   ||
                                           is( T == ulong )/+||
                                           is( T == ucent  )+/;
    }
    
    /// substitutes classes with void* 
    template ClassPtr(T){
        static if (is(T==class)){
            alias void* ClassPtr;
        } else {
            alias T ClassPtr;
        }
    }
}

extern(C) void thread_yield();

// NOTE: Strictly speaking, the x86 supports atomic operations on
//       unaligned values.  However, this is far slower than the
//       common case, so such behavior should be prohibited.
template atomicValueIsProperlyAligned( T )
{
    bool atomicValueIsProperlyAligned( size_t addr )
    {
        return addr % ClassPtr!(T).sizeof == 0;
    }
}

/*
 * A barrier does not allow some kinds of intermixing and out of order execution
 * and ensures that all operations of one kind are executed before the operations of the other type
 * which kind of mixing are not allowed depends from the template arguments
 * These are global barriers: the whole memory is synchronized (devices excluded if device is false)
 *
 * the actual barrier eforced might be stronger than the requested one
 *
 * if ll is true loads before the barrier are not allowed to mix with loads after the barrier
 * if ls is true loads before the barrier are not allowed to mix with stores after the barrier
 * if sl is true stores before the barrier are not allowed to mix with loads after the barrier
 * if ss is true stores before the barrier are not allowed to mix with stores after the barrier
 * if device is true als uncached and device memory is synchronized
 *
 * Barriers are typically paired
 * 
 * For example if you want to ensure that all writes
 * are done before setting a flags that communicates that an objects is initialized you would
 * need memoryBarrier(false,false,false,true) before setting the flag.
 * To read that flag before reading the rest of the object you would need a
 * memoryBarrier(true,false,false,false) after having read the flag.
 *
 * I believe that these two barriers are called acquire and release, but you find several
 * incompatible definitions around (some obviously wrong), so some care migth be in order
 * To be safer memoryBarrier(false,true,false,true) might be used for acquire, and
 * memoryBarrier(true,false,true,false) for release which are slighlty stronger.
 * 
 * These barriers are also called write barrier and read barrier respectively.
 *
 * A full memory fence is (true,true,true,true) and ensures that stores and loads before the
 * barrier are done before stores and loads after it.
 * Keep in mind even with a full barrier you still normally need two of them, to avoid that the
 * other process reorders loads (for example) and still sees things in the wrong order.
*/
version( LDC )
{
    void memoryBarrier(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        llvm_memory_barrier(ll,ls,sl,ss,device);
    }
} else version(D_InlineAsm_X86){
    void memoryBarrier(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        static if (device) {
            if (ls || sl || ll || ss){
                // cpid should sequence even more than mfence
                volatile asm {
                    push EBX;
                    mov EAX, 0; // model, stepping
                    cpuid;
                    pop EBX;
                }
            }
        } else static if (ls || sl || (ll && ss)){ // use a sequencing operation like cpuid or simply cmpxch instead?
            volatile asm {
                mfence;
            }
            // this is supposedly faster and correct, but let's play it safe and use the specific instruction
            // push rax
            // xchg rax
            // pop rax
        } else static if (ll){
            volatile asm {
                lfence;
            }
        } else static if( ss ){
            volatile asm {
                sfence;
            }
        }
    }
} else version(D_InlineAsm_X86_64){
    void memoryBarrier(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        static if (device) {
            if (ls || sl || ll || ss){
                // cpid should sequence even more than mfence
                volatile asm {
                    push RBX;
                    mov RAX, 0; // model, stepping
                    cpuid;
                    pop RBX;
                }
            }
        } else static if (ls || sl || (ll && ss)){ // use a sequencing operation like cpuid or simply cmpxch instead?
            volatile asm {
                mfence;
            }
            // this is supposedly faster and correct, but let's play it safe and use the specific instruction
            // push rax
            // xchg rax
            // pop rax
        } else static if (ll){
            volatile asm {
                lfence;
            }
        } else static if( ss ){
            volatile asm {
                sfence;
            }
        }
    }
} else {
    pragma(msg,"WARNING: no atomic operations on this architecture");
    pragma(msg,"WARNING: this is *slow* you probably want to change this!");
    int dummy;
    // acquires a lock... probably you will want to skip this
    void memoryBarrier(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        synchronized { dummy=1; }
    }
    enum{LockVersion=true}
}

static if (!is(typeof(LockVersion))) {
    enum{LockVersion=false}
}

// use stricter fences
enum{strictFences=false}

/// Utility function for a write barrier (disallow store and store reorderig.)
void writeBarrier(){
    memoryBarrier!(false,false,strictFences,true)();
}
/// Utility function for a read barrier (disallow load and load reorderig.)
void readBarrier(){
    memoryBarrier!(true,strictFences,false,false)();
}
/// Utility function for a full barrier (disallow reorderig.)
void fullBarrier(){
    memoryBarrier!(true,true,true,true)();
}

/*
 * Atomic swap.
 * val and newval in one atomic operation
 * barriers are not implied, just atomicity!
*/
version(LDC){
    T atomicSwap( T )( ref T val, T newval )
    {
        T oldval = void;
        static if (isPointerOrClass!(T))
        {
            oldval = cast(T)llvm_atomic_swap!(size_t)(cast(size_t*)&val, cast(size_t)newval);
        }
        else static if (is(T == bool))
        {
            oldval = llvm_atomic_swap!(ubyte)(cast(ubyte*)&val, newval?1:0)?0:1;
        }
        else
        {
            oldval = llvm_atomic_swap!(T)(&val, newval);
        }
        return oldval;
    }
} else version(D_InlineAsm_X86) {
    T atomicSwap( T )( inout T val, T newval )
    in {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( T.sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) &val ) );
        else
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    } body {
        T*posVal=&val;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov AL, newval;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [ECX], AL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov AX, newval;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [ECX], AX;
            }
        }
        else static if( T.sizeof == int.sizeof ) {
            volatile asm {
                mov EAX, newval;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [ECX], EAX;
            }
        }
        else static if( T.sizeof == long.sizeof ) {
            // 8 Byte swap on 32-Bit Processor, use CAS?
            static assert( false, "Invalid template type specified, 8bytes in 32 bit mode: "~T.stringof );
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else version (D_InlineAsm_X86_64){
    T atomicSwap( T )( inout T val, T newval )
    in {
        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    } body {
        T*posVal=&val;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov AL, newval;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [RCX], AL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov AX, newval;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [RCX], AX;
            }
        }
        else static if( T.sizeof == int.sizeof ) {
            volatile asm {
                mov EAX, newval;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [RCX], EAX;
            }
        }
        else static if( T.sizeof == long.sizeof ) {
            volatile asm {
                mov RAX, newval;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                xchg [RCX], RAX;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else {
    T atomicSwap( T )( inout T val, T newval )
    in {
        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    } body {
        T oldVal;
        synchronized(typeid(T)){
            oldVal=val;
            val=newval;
        }
        return oldVal;
    }
}

//---------------------
// internal conversion template
private T aCasT(T,V)(ref T val, T newval, T equalTo){
    union UVConv{V v; T t;}
    union UVPtrConv{V *v; T *t;}
    UVConv vNew,vOld,vAtt;
    UVPtrConv valPtr;
    vNew.t=newval;
    vOld.t=equalTo;
    valPtr.t=&val;
    vAtt.v=atomicCAS(*valPtr.v,vNew.v,vOld.v);
    return vAtt.t;
}
/// internal reduction 
private T aCas(T)(ref T val, T newval, T equalTo){
    static if (T.sizeof==1){
        return aCasT!(T,ubyte)(val,newval,equalTo);
    } else static if (T.sizeof==2){
        return aCasT!(T,ushort)(val,newval,equalTo);
    } else static if (T.sizeof==4){
        return aCasT!(T,uint)(val,newval,equalTo);
    } else static if (T.sizeof==8){ // unclear if it is always supported...
        return aCasT!(T,ulong)(val,newval,equalTo);
    } else {
        static assert(0,"invalid type "~T.stringof);
    }
}

/*
 * Atomic compare & exchange (can be used to implement everything else)
 * stores newval into val if val==equalTo in one atomic operation.
 * Barriers are not implied, just atomicity!
 * Returns the value that is checked against equalTo (i.e. an exchange was performed 
 * if result==equalTo, otherwise one can use the result as the current value).
*/
version(LDC){
    T atomicCAS( T )( ref T val, T newval, T equalTo )
    {
        T oldval = void;
        static if (isPointerOrClass!(T))
        {
            oldval = cast(T)cast(void*)llvm_atomic_cmp_swap!(size_t)(cast(size_t*)cast(void*)&val, cast(size_t)cast(void*)equalTo, cast(size_t)cast(void*)newval);
        }
        else static if (is(T == bool)) // correct also if bol has different size?
        {
            oldval = aCas(val,newval,equalTo); // assuming true is *always* 1 and not a non zero value...
        }
        else static if (isIntegerType!(T))
        {
            oldval = llvm_atomic_cmp_swap!(T)(&val, equalTo, newval);
        } else {
            oldval = aCas(val,newval,equalTo);
        }
        return oldval;
    }
} else version(D_InlineAsm_X86) {
    version(darwin){
        extern(C) ubyte OSAtomicCompareAndSwap64(long oldValue, long newValue,
                 long *theValue); // assumes that in C sizeof(_Bool)==1 (as given in osx IA-32 ABI)
    }
    T atomicCAS( T )( ref T val, T newval, T equalTo )
    in {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use size_t as the align type here.
        static if( ClassPtr!(T).sizeof > size_t.sizeof )
            assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) &val ) );
        else
            assert( atomicValueIsProperlyAligned!(ClassPtr!(T))( cast(size_t) &val ) );
    } body {
        T*posVal=&val;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov DL, newval;
                mov AL, equalTo;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], DL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov DX, newval;
                mov AX, equalTo;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], DX;
            }
        }
        else static if( ClassPtr!(T).sizeof == int.sizeof ) {
            volatile asm {
                mov EDX, newval;
                mov EAX, equalTo;
                mov ECX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [ECX], EDX;
            }
        }
        else static if( T.sizeof == long.sizeof ) {
            // 8 Byte StoreIf on 32-Bit Processor
            version(darwin){
                union UVConv{long v; T t;}
                union UVPtrConv{long *v; T *t;}
                UVConv vEqual,vNew;
                UVPtrConv valPtr;
                vEqual.t=equalTo;
                vNew.t=newval;
                valPtr.t=&val;
                while(1){
                    if(OSAtomicCompareAndSwap64(vEqual.v, vNew.v, valPtr.v)!=0)
                    {
                        return equalTo;
                    } else {
                        volatile {
                            T res=val;
                            if (res!is equalTo) return res;
                        }
                    }
                }
            } else {
                T res;
                volatile asm
                {
                    push EDI;
                    push EBX;
                    lea EDI, newval;
                    mov EBX, [EDI];
                    mov ECX, 4[EDI];
                    lea EDI, equalTo;
                    mov EAX, [EDI];
                    mov EDX, 4[EDI];
                    mov EDI, val;
                    lock; // lock always needed to make this op atomic
                    cmpxch8b [EDI];
                    lea EDI, res;
                    mov [EDI], EAX;
                    mov 4[EDI], EDX;
                    pop EBX;
                    pop EDI;
                }
                return res;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else version (D_InlineAsm_X86_64){
    T atomicCAS( T )( ref T val, T newval, T equalTo )
    in {
        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    } body {
        T*posVal=&val;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov DL, newval;
                mov AL, equalTo;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], DL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov DX, newval;
                mov AX, equalTo;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], DX;
            }
        }
        else static if( ClassPtr!(T).sizeof == int.sizeof ) {
            volatile asm {
                mov EDX, newval;
                mov EAX, equalTo;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], EDX;
            }
        }
        else static if( ClassPtr!(T).sizeof == long.sizeof ) {
            volatile asm {
                mov RDX, newval;
                mov RAX, equalTo;
                mov RCX, posVal;
                lock; // lock always needed to make this op atomic
                cmpxchg [RCX], RDX;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else {
    T atomicCAS( T )( ref T val, T newval, T equalTo )
    in {
        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    } body {
        T oldval;
        synchronized(typeid(T)){
            oldval=val;
            if(oldval==equalTo) {
                val=newval;
            }
        }
        return oldval;
    }
}

bool atomicCASB(T)( ref T val, T newval, T equalTo ){
    return (equalTo is atomicCAS(val,newval,equalTo));
}

/*
 * Loads a value from memory.
 *
 * At the moment it is assumed that all aligned memory accesses are atomic
 * in the sense that all bits are consistent with some store.
 *
 * Remove this? I know no actual architecture where this would be different.
*/
T atomicLoad(T)(ref T val)
in {
    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
    static assert(ClassPtr!(T).sizeof<=size_t.sizeof,"invalid size for "~T.stringof);
} body {
    volatile T res=val;
    return res;
}

/*
 * Stores a value the the memory.
 *
 * At the moment it is assumed that all aligned memory accesses are atomic
 * in the sense that a load either sees the complete store or the previous value.
 *
 * Remove this? I know no actual architecture where this would be different.
*/
void atomicStore(T)(ref T val, T newVal)
in {
        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ), "invalid alignment" );
        static assert(ClassPtr!(T).sizeof<=size_t.sizeof,"invalid size for "~T.stringof);
} body {
    volatile val=newVal;
}

/*
 * Increments the given value and returns the previous value with an atomic operation.
 *
 * Some architectures might allow just increments/decrements by 1.
 * No barriers implied, only atomicity!
*/
version(LDC){
    T atomicAdd(T)(ref T val, T incV){
        static if (isPointerOrClass!(T))
        {
            return cast(T)llvm_atomic_load_add!(size_t)(cast(size_t*)&val, incV);
        }
        else static if (isIntegerType!(T))
        {
            static assert( isIntegerType!(T), "invalid type "~T.stringof );
            return llvm_atomic_load_add!(T)(&val, cast(T)incV);
        } else {
            return atomicOp(val,delegate T(T a){ return a+incV; });
        }
    }
} else version (D_InlineAsm_X86){
    T atomicAdd(T,U=T)(ref T val, U incV_){
        T incV=cast(T)incV_;
        static if (isIntegerType!(T)||isPointerOrClass!(T)){
            T* posVal=&val;
            T res;
            static if (T.sizeof==1){
                volatile asm {
                    mov DL, incV;
                    mov ECX, posVal;
                    lock;
                    xadd byte ptr [ECX],DL;
                    mov byte ptr res[EBP],DL;
                }
            } else static if (T.sizeof==2){
                volatile asm {
                    mov DX, incV;
                    mov ECX, posVal;
                    lock;
                    xadd short ptr [ECX],DX;
                    mov short ptr res[EBP],DX;
                }
            } else static if (T.sizeof==4){
                volatile asm
                {
                    mov EDX, incV;
                    mov ECX, posVal;
                    lock;
                    xadd int ptr [ECX],EDX;
                    mov int ptr res[EBP],EDX;
                }
            } else static if (T.sizeof==8){
                return atomicOp(val,delegate (T x){ return x+incV; });
            } else {
                static assert(0,"Unsupported type size");
            }
            return res;
        } else {
            return atomicOp(val,delegate T(T a){ return a+incV; });
        }
    }
} else version (D_InlineAsm_X86_64){
    T atomicAdd(T,U=T)(ref T val, U incV_){
        T incV=cast(T)incV_;
        static if (isIntegerType!(T)||isPointerOrClass!(T)){
            T* posVal=&val;
            T res;
            static if (T.sizeof==1){
                volatile asm {
                    mov DL, incV;
                    mov RCX, posVal;
                    lock;
                    xadd byte ptr [RCX],DL;
                    mov byte ptr res[EBP],DL;
                }
            } else static if (T.sizeof==2){
                volatile asm {
                    mov DX, incV;
                    mov RCX, posVal;
                    lock;
                    xadd short ptr [RCX],DX;
                    mov short ptr res[EBP],DX;
                }
            } else static if (T.sizeof==4){
                volatile asm
                {
                    mov EDX, incV;
                    mov RCX, posVal;
                    lock;
                    xadd int ptr [RCX],EDX;
                    mov int ptr res[EBP],EDX;
                }
            } else static if (T.sizeof==8){
                volatile asm
                {
                    mov RAX, val;
                    mov RDX, incV;
                    lock; // lock always needed to make this op atomic
                    xadd qword ptr [RAX],RDX;
                    mov res[EBP],RDX;
                }
            } else {
                static assert(0,"Unsupported type size for type:"~T.stringof);
            }
            return res;
        } else {
            return atomicOp(val,delegate T(T a){ return a+incV; });
        }
    }
} else {
    static if (LockVersion){
        T atomicAdd(T,U=T)(ref T val, U incV_){
            T incV=cast(T)incV_;
            static assert( isIntegerType!(T)||isPointerOrClass!(T),"invalid type: "~T.stringof );
            synchronized(typeid(T)){
                T oldV=val;
                val+=incV;
                return oldV;
            }
        }
    } else {
        T atomicAdd(T,U=T)(ref T val, U incV_){
            T incV=cast(T)incV_;
            static assert( isIntegerType!(T)||isPointerOrClass!(T),"invalid type: "~T.stringof );
            synchronized(typeid(T)){
                T oldV,newVal,nextVal;
                volatile nextVal=val;
                do{
                    oldV=nextVal;
                    newV=oldV+incV;
                    auto nextVal=atomicCAS!(T)(val,newV,oldV);
                } while(nextVal!=oldV)
                return oldV;
            }
        }
    }
}

/*
 * Applies a pure function atomically.
 * The function should be pure as it might be called several times to ensure atomicity
 * The function should take a short time to compute otherwise contention is possible
 * and no "fair" share is applied between fast function (more likely to succeed) and
 * the others (i.e. do not use this in case of high contention).
*/
T atomicOp(T)(ref T val, T delegate(T) f){
    T oldV,newV,nextV;
    int i=0;
    nextV=val;
    do {
        oldV=nextV;
        newV=f(oldV);
        nextV=aCas!(T)(val,newV,oldV);
        if (nextV is oldV || newV is oldV) return oldV;
    } while(++i<200)
    while (true){
        thread_yield();
        volatile oldV=val;
        newV=f(oldV);
        nextV=aCas!(T)(val,newV,oldV);
        if (nextV is oldV || newV is oldV) return oldV;
    }
}

/*
 * Reads a flag (ensuring that other accesses can not happen before you read it).
*/
T flagGet(T)(ref T flag){
    T res;
    volatile res=flag;
    memoryBarrier!(true,false,strictFences,false)();
    return res;
}

/*
 * Sets a flag (ensuring that all pending writes are executed before this).
 * the original value is returned.
*/
T flagSet(T)(ref T flag,T newVal){
    memoryBarrier!(false,strictFences,false,true)();
    return atomicSwap(flag,newVal);
}

/*
 * Writes a flag (ensuring that all pending writes are executed before this).
 * the original value is returned.
*/
T flagOp(T)(ref T flag,T delegate(T) op){
    memoryBarrier!(false,strictFences,false,true)();
    return atomicOp(flag,op);
}

/*
 * Reads a flag (ensuring that all pending writes are executed before this).
*/
T flagAdd(T)(ref T flag,T incV=cast(T)1){
    static if (!LockVersion)
        memoryBarrier!(false,strictFences,false,true)();
    return atomicAdd(flag,incV);
}

/*
 * Returns the value of val and increments it in one atomic operation
 * useful for counters, and to generate unique values (fast)
 * no barriers are implied.
*/
T nextValue(T)(ref T val){
    return atomicAdd(val,cast(T)1);
}
