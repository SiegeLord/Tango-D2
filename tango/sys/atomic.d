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
 * The atomic module is intended to provide some basic support for lock-free
 * concurrent programming.  Some common operations are defined, each of which
 * may be performed using the specified memory barrier or a less granular
 * barrier if the hardware does not support the version requested.  This
 * model is based on a design by Alexander Terekhov as outlined in
 * <a href=http://groups.google.com/groups?threadm=3E4820EE.6F408B25%40web.de>
 * this thread</a>.
 *
 * Design Issues:
 *
 * Originally, all functions were intended to be either static or non-static
 * members of the Atomic class.  However, DMD currently can not disambiguate
 * between the two if they have the same name, so the current design was
 * chosen.  This design also seems to be a bit more readable, so it may remain
 * even if the compiler bug (?) is fixed.
 *
 * Future Directions:
 *
 * As many architectures provide optimized atomic support for common integer
 * operations (such as increment, decrement, etc), these may be added in some
 * form--perhaps as additional global functions and in an AtomicValue type.
 */
module tango.sys.atomic;


////////////////////////////////////////////////////////////////////////////////
// Synchronization Options
////////////////////////////////////////////////////////////////////////////////


/**
 * Memory synchronization flag.  If the supplied option is not available on the
 * current platform then a stronger method will be used instead.
 */
enum msync
{
    hlb,    /// hoist-load barrier
    ddhlb,  /// hoist-load barrier with data-dependency "hint"
    hsb,    /// hoist-store barrier
    slb,    /// sink-load barrier
    ssb,    /// sink-store barrier
    acq,    /// hoist-load + hoist-store barrier
    rel,    /// sink-load + sink-store barrier
    none    /// naked
}


////////////////////////////////////////////////////////////////////////////////
// Internal Type Checking
////////////////////////////////////////////////////////////////////////////////


private
{
    import tango.core.traits;


    template isValidAtomicType( T )
    {
        const bool isValidAtomicType = T.sizeof == byte.sizeof  ||
                                       T.sizeof == short.sizeof ||
                                       T.sizeof == int.sizeof   ||
                                       T.sizeof == long.sizeof;
    }


    template isValidNumericType( T )
    {
        const bool isValidNumericType = isIntegerType!( T ) ||
                                        isPointerType!( T );
    }


    template isHoistOp( msync ms )
    {
        const bool isHoistOp = ms == msync.hlb   ||
                               ms == msync.ddhlb ||
                               ms == msync.hsb   ||
                               ms == msync.acq;
    }


    template isSinkOp( msync ms )
    {
        const bool isSinkOp = ms == msync.slb ||
                              ms == msync.ssb ||
                              ms == msync.rel;
    }
}


////////////////////////////////////////////////////////////////////////////////
// x86 Atomic Function Implementation
////////////////////////////////////////////////////////////////////////////////


private
{
    version( X86 )
    {
        ////////////////////////////////////////////////////////////////////////
        // x86 Value Requirements
        ////////////////////////////////////////////////////////////////////////


        //
        // NOTE: Strictly speaking, the x86 supports atomic operations on
        //       unaligned values.  However, this is far slower than the
        //       common case, so such behavior should be prohibited.
        //
        template atomicValueIsProperlyAligned( T )
        {
            bool atomicValueIsProperlyAligned( size_t addr )
            {
                return addr % T.sizeof == 0;
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Load
        ////////////////////////////////////////////////////////////////////////


        template doAtomicLoad( bool membar, T )
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Load
                ////////////////////////////////////////////////////////////////


                T doAtomicLoad( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            mov AL, [EAX];
                        }
                    }
                    else
                    {
                        volatile
                        {
                            return val;
                        }
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Load
                ////////////////////////////////////////////////////////////////


                T doAtomicLoad( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            mov AX, [EAX];
                        }
                    }
                    else
                    {
                        volatile
                        {
                            return val;
                        }
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Load
                ////////////////////////////////////////////////////////////////


                T doAtomicLoad( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            mov EAX, [EAX];
                        }
                    }
                    else
                    {
                        volatile
                        {
                            return val;
                        }
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Load
                ////////////////////////////////////////////////////////////////


                version( X86_64 )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Load on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    T doAtomicLoad( inout T val )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                lock;
                                mov RAX, [RAX];
                            }
                        }
                        else
                        {
                            volatile
                            {
                                return val;
                            }
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Load on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Store
        ////////////////////////////////////////////////////////////////////////


        template doAtomicStore( bool membar, T )
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Store
                ////////////////////////////////////////////////////////////////


                void doAtomicStore( inout T val, T newval )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov BL, newval;
                            lock;
                            xchg [EAX], BL;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov BL, newval;
                            mov [EAX], BL;
                        }
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Store
                ////////////////////////////////////////////////////////////////


                void doAtomicStore( inout T val, T newval )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov BX, newval;
                            lock;
                            xchg [EAX], BX;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov BX, newval;
                            mov [EAX], BX;
                        }
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Store
                ////////////////////////////////////////////////////////////////


                void doAtomicStore( inout T val, T newval )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov EBX, newval;
                            lock;
                            xchg [EAX], EBX;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            mov EBX, newval;
                            mov [EAX], EBX;
                        }
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Store
                ////////////////////////////////////////////////////////////////


                version( X86_64 )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Store on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    void doAtomicStore( inout T val, T newval )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                mov RBX, newval;
                                lock;
                                xchg [RAX], RBX;
                            }
                        }
                        else
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                mov RBX, newval;
                                mov [RAX], RBX;
                            }
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Store on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Store If
        ////////////////////////////////////////////////////////////////////////


        template doAtomicStoreIf( bool membar, T )
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                bool doAtomicStoreIf( inout T val, T newval, T equalTo )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov BL, newval;
                            mov AL, equalTo;
                            mov ECX, val;
                            lock;
                            cmpxchg [ECX], BL;
                            setz AL;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov BL, newval;
                            mov AL, equalTo;
                            mov ECX, val;
                            lock; // lock needed to make this op atomic
                            cmpxchg [ECX], BL;
                            setz AL;
                        }
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                bool doAtomicStoreIf( inout T val, T newval, T equalTo )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov BX, newval;
                            mov AX, equalTo;
                            mov ECX, val;
                            lock;
                            cmpxchg [ECX], BX;
                            setz AL;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov BX, newval;
                            mov AX, equalTo;
                            mov ECX, val;
                            lock; // lock needed to make this op atomic
                            cmpxchg [ECX], BX;
                            setz AL;
                        }
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                bool doAtomicStoreIf( inout T val, T newval, T equalTo )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EBX, newval;
                            mov EAX, equalTo;
                            mov ECX, val;
                            lock;
                            cmpxchg [ECX], EBX;
                            setz AL;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EBX, newval;
                            mov EAX, equalTo;
                            mov ECX, val;
                            lock; // lock needed to make this op atomic
                            cmpxchg [ECX], EBX;
                            setz AL;
                        }
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                version( X86_64 )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte StoreIf on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    bool doAtomicStoreIf( inout T val, T newval, T equalTo )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                mov RBX, newval;
                                mov RAX, equalTo;
                                mov RCX, val;
                                lock;
                                cmpxchg [RCX], RBX;
                                setz AL;
                            }
                        }
                        else
                        {
                            volatile asm
                            {
                                mov RBX, newval;
                                mov RAX, equalTo;
                                mov RCX, val;
                                lock; // lock needed to make this op atomic
                                cmpxchg [RCX], RBX;
                                setz AL;
                            }
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte StoreIf on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    bool doAtomicStoreIf( inout T val, T newval, T equalTo )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                lea	EDI, newval;
                                mov	EBX, [EDI];
                                mov	ECX, 4[EDI];
                                lea	EDI, equalTo;
                                mov	EAX, [EDI];
                                mov	EDX, 4[EDI];
                                mov	EDI, val;
                                lock;
                                cmpxch8b [EDI];
                                setz AL;
                            }
                        }
                        else
                        {
                            volatile asm
                            {
                                lea	EDI, newval;
                                mov	EBX, [EDI];
                                mov	ECX, 4[EDI];
                                lea	EDI, equalTo;
                                mov	EAX, [EDI];
                                mov	EDX, 4[EDI];
                                mov	EDI, val;
                                lock; // lock needed to make this op atomic
                                cmpxch8b [EDI];
                                setz AL;
                            }
                        }
                    }
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Increment
        ////////////////////////////////////////////////////////////////////////


        template doAtomicIncrement( bool membar, T )
        {
            //
            // NOTE: This operation is only valid for integer or pointer types
            //
            static assert( isValidNumericType!(T) );

            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Increment
                ////////////////////////////////////////////////////////////////


                T doAtomicIncrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            inc [EAX];
                            mov AL, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            inc [EAX];
                            mov AL, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Increment
                ////////////////////////////////////////////////////////////////


                T doAtomicIncrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            inc [EAX];
                            mov AX, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            inc [EAX];
                            mov AX, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Increment
                ////////////////////////////////////////////////////////////////


                T doAtomicIncrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            inc [EAX];
                            mov EAX, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            inc [EAX];
                            mov EAX, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Increment
                ////////////////////////////////////////////////////////////////


                version( X86_64 )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Increment on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    T doAtomicIncrement( inout T val )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                lock;
                                inc [RAX];
                                mov RAX, [RAX];
                            }
                        }
                        else
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                lock; // lock needed to make this op atomic
                                inc [RAX];
                                mov RAX, [RAX];
                            }
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Increment on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Decrement
        ////////////////////////////////////////////////////////////////////////


        template doAtomicDecrement( bool membar, T )
        {
            //
            // NOTE: This operation is only valid for integer or pointer types
            //
            static assert( isValidNumericType!(T) );

            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Decrement
                ////////////////////////////////////////////////////////////////


                T doAtomicDecrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            dec [EAX];
                            mov AL, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            dec [EAX];
                            mov AL, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Decrement
                ////////////////////////////////////////////////////////////////


                T doAtomicDecrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            dec [EAX];
                            mov AX, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            dec [EAX];
                            mov AX, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Decrement
                ////////////////////////////////////////////////////////////////


                T doAtomicDecrement( inout T val )
                in
                {
                    assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                }
                body
                {
                    static if( membar )
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock;
                            dec [EAX];
                            mov EAX, [EAX];
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov EAX, val;
                            lock; // lock needed to make this op atomic
                            dec [EAX];
                            mov EAX, [EAX];
                        }
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Decrement
                ////////////////////////////////////////////////////////////////


                version( X86_64 )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Decrement on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    T doAtomicDecrement( inout T val )
                    in
                    {
                        assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
                    }
                    body
                    {
                        static if( membar )
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                lock;
                                dec [RAX];
                                mov RAX, [RAX];
                            }
                        }
                        else
                        {
                            volatile asm
                            {
                                mov RAX, val;
                                lock; // lock needed to make this op atomic
                                dec [RAX];
                                mov RAX, [RAX];
                            }
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////////
                    // 8 Byte Decrement on 32-Bit Processor
                    ////////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// x86 Atomic Function Accessors
////////////////////////////////////////////////////////////////////////////////


version( X86 )
{
    //
    // NOTE: x86 loads implicitly have acquire semantics so a membar is only necessary on release
    //

    /**
     * Refreshes the contents of 'val' from main memory.  This operation is both lock-free and atomic.
     *
     * Returns:
     *  The loaded value.
     *
     * Params:
     *  val = The value to load.  This value must be properly aligned.
     */
    template atomicLoad( msync ms : msync.none, T )  { alias doAtomicLoad!(isSinkOp!(ms),T) atomicLoad; }
    template atomicLoad( msync ms : msync.hlb, T )   { alias doAtomicLoad!(isSinkOp!(ms),T) atomicLoad; } /// ditto
    template atomicLoad( msync ms : msync.ddhlb, T ) { alias doAtomicLoad!(isSinkOp!(ms),T) atomicLoad; } /// ditto
    template atomicLoad( msync ms : msync.acq, T )   { alias doAtomicLoad!(isSinkOp!(ms),T) atomicLoad; } /// ditto

    //
    // NOTE: x86 stores implicitly have release semantics so a membar is only necessary on acquires
    //

    /**
     * Stores 'newval' to the memory referenced by 'val'.  This operation is both lock-free and atomic.
     *
     * Params:
     *  val     = The destination variable.
     *  newval  = The value to store.
     */
    template atomicStore( msync ms : msync.none, T ) { alias doAtomicStore!(isHoistOp!(ms),T) atomicStore; }
    template atomicStore( msync ms : msync.ssb, T )  { alias doAtomicStore!(isHoistOp!(ms),T) atomicStore; } /// ditto
    template atomicStore( msync ms : msync.acq, T )  { alias doAtomicStore!(isHoistOp!(ms),T) atomicStore; } /// ditto
    template atomicStore( msync ms : msync.rel, T )  { alias doAtomicStore!(isHoistOp!(ms),T) atomicStore; } /// ditto

    /**
     * Stores 'newval' to the memory referenced by 'val' if val is equal to 'equalTo'.  This operation
     * is both lock-free and atomic.
     *
     * Returns:
     *  true if the store occurred, false if not.
     *
     * Params:
     *  val     = The destination variable.
     *  newval  = The value to store.
     *  equalTo = The comparison value.
     */
    template atomicStoreIf( msync ms : msync.none, T ) { alias doAtomicStoreIf!(ms!=msync.none,T) atomicStoreIf; }
    template atomicStoreIf( msync ms : msync.ssb, T )  { alias doAtomicStoreIf!(ms!=msync.none,T) atomicStoreIf; } /// ditto
    template atomicStoreIf( msync ms : msync.acq, T )  { alias doAtomicStoreIf!(ms!=msync.none,T) atomicStoreIf; } /// ditto
    template atomicStoreIf( msync ms : msync.rel, T )  { alias doAtomicStoreIf!(ms!=msync.none,T) atomicStoreIf; } /// ditto

    /**
     * This operation is only legal for built-in value and pointer types, and is equivalent to an atomic
     * "val = val + 1" operation.  This function exists to facilitate use of the optimized increment
     * instructions provided by some architecures.  If no such instruction exists on the target platform
     * then the behavior will perform the operation using more traditional means.  This operation is both
     * lock-free and atomic.
     *
     * Returns:
     *  The result of an atomicLoad of val immediately following the increment operation.  This value
     *  is not required to be equal to the newly stored value.  Thus, competing writes are allowed to
     *  occur between the increment and successive load operation.
     *
     * Params:
     *  val = The value to increment.
     */
    template atomicIncrement( msync ms : msync.none, T ) { alias doAtomicIncrement!(ms!=msync.none,T) atomicIncrement; }
    template atomicIncrement( msync ms : msync.ssb, T )  { alias doAtomicIncrement!(ms!=msync.none,T) atomicIncrement; } /// ditto
    template atomicIncrement( msync ms : msync.acq, T )  { alias doAtomicIncrement!(ms!=msync.none,T) atomicIncrement; } /// ditto
    template atomicIncrement( msync ms : msync.rel, T )  { alias doAtomicIncrement!(ms!=msync.none,T) atomicIncrement; } /// ditto

    /**
     * This operation is only legal for built-in value and pointer types, and is equivalent to an atomic
     * "val = val - 1" operation.  This function exists to facilitate use of the optimized decrement
     * instructions provided by some architecures.  If no such instruction exists on the target platform
     * then the behavior will perform the operation using more traditional means.  This operation is both
     * lock-free and atomic.
     *
     * Returns:
     *  The result of an atomicLoad of val immediately following the increment operation.  This value
     *  is not required to be equal to the newly stored value.  Thus, competing writes are allowed to
     *  occur between the increment and successive load operation.
     *
     * Params:
     *  val = The value to decrement.
     */
    template atomicDecrement( msync ms : msync.none, T ) { alias doAtomicDecrement!(ms!=msync.none,T) atomicDecrement; }
    template atomicDecrement( msync ms : msync.ssb, T )  { alias doAtomicDecrement!(ms!=msync.none,T) atomicDecrement; } /// ditto
    template atomicDecrement( msync ms : msync.acq, T )  { alias doAtomicDecrement!(ms!=msync.none,T) atomicDecrement; } /// ditto
    template atomicDecrement( msync ms : msync.rel, T )  { alias doAtomicDecrement!(ms!=msync.none,T) atomicDecrement; } /// ditto
}


////////////////////////////////////////////////////////////////////////////////
// Atomic
////////////////////////////////////////////////////////////////////////////////


/**
 * This class represents a value which will be subject to competing access.  All accesses to
 * this value will be synchronized with main memory, and various memory barriers may be
 * employed for instruction ordering.  Any primitive type of size equal to or smaller than
 * the memory bus size is allowed, so 32-bit machines may use values with size <= int.sizeof
 * and 64-bit machines may use values with size <= long.sizeof.  The one exception to this
 * rule is that architectures that support DCAS will allow double-wide storeIf operations.
 * The 32-bit x86 architecture, for example, supports 64-bit storeIf operations.
 */
struct Atomic( T )
{
    /**
     * Refreshes the contents of this value from main memory.  This operation is both lock-free and atomic.
     *
     * Returns:
     *  The loaded value.
     */
    template load( msync ms : msync.none )  { T load() { return atomicLoad!(ms,T)( m_val ); } }
    template load( msync ms : msync.hlb )   { T load() { return atomicLoad!(ms,T)( m_val ); } } /// ditto
    template load( msync ms : msync.ddhlb ) { T load() { return atomicLoad!(ms,T)( m_val ); } } /// ditto
    template load( msync ms : msync.acq )   { T load() { return atomicLoad!(ms,T)( m_val ); } } /// ditto

    /**
     * Stores 'newval' to the memory referenced by this value.  This operation is both lock-free and atomic.
     *
     * Params:
     *  newval  = The value to store.
     */
    template store( msync ms : msync.none ) { void store( T newval ) { atomicStore!(ms,T)( m_val, newval ); } }
    template store( msync ms : msync.ssb )  { void store( T newval ) { atomicStore!(ms,T)( m_val, newval ); } } /// ditto
    template store( msync ms : msync.acq )  { void store( T newval ) { atomicStore!(ms,T)( m_val, newval ); } } /// ditto
    template store( msync ms : msync.rel )  { void store( T newval ) { atomicStore!(ms,T)( m_val, newval ); } } /// ditto

    /**
     * Stores 'newval' to the memory referenced by this value if val is equal to 'equalTo'.  This operation
     * is both lock-free and atomic.
     *
     * Returns:
     *  true if the store occurred, false if not.
     *
     * Params:
     *  newval  = The value to store.
     *  equalTo = The comparison value.
     */
    template storeIf( msync ms : msync.none ) { bool storeIf( T newval, T equalTo ) { return atomicStoreIf!(ms,T)( m_val, newval, equalTo ); } }
    template storeIf( msync ms : msync.ssb )  { bool storeIf( T newval, T equalTo ) { return atomicStoreIf!(ms,T)( m_val, newval, equalTo ); } } /// ditto
    template storeIf( msync ms : msync.acq )  { bool storeIf( T newval, T equalTo ) { return atomicStoreIf!(ms,T)( m_val, newval, equalTo ); } } /// ditto
    template storeIf( msync ms : msync.rel )  { bool storeIf( T newval, T equalTo ) { return atomicStoreIf!(ms,T)( m_val, newval, equalTo ); } } /// ditto

    static if( isValidNumericType!(T) )
    {
        /**
         * This operation is only legal for built-in value and pointer types, and is equivalent to an atomic
         * "val = val + 1" operation.  This function exists to facilitate use of the optimized increment
         * instructions provided by some architecures.  If no such instruction exists on the target platform
         * then the behavior will perform the operation using more traditional means.  This operation is both
         * lock-free and atomic.
         *
         * Returns:
         *  The result of an atomicLoad of val immediately following the increment operation.  This value
         *  is not required to be equal to the newly stored value.  Thus, competing writes are allowed to
         *  occur between the increment and successive load operation.
         */
        template increment( msync ms : msync.none ) { T increment() { return atomicIncrement!(ms,T)( m_val ); } }
        template increment( msync ms : msync.ssb )  { T increment() { return atomicIncrement!(ms,T)( m_val ); } } /// ditto
        template increment( msync ms : msync.acq )  { T increment() { return atomicIncrement!(ms,T)( m_val ); } } /// ditto
        template increment( msync ms : msync.rel )  { T increment() { return atomicIncrement!(ms,T)( m_val ); } } /// ditto

        /**
         * This operation is only legal for built-in value and pointer types, and is equivalent to an atomic
         * "val = val - 1" operation.  This function exists to facilitate use of the optimized decrement
         * instructions provided by some architecures.  If no such instruction exists on the target platform
         * then the behavior will perform the operation using more traditional means.  This operation is both
         * lock-free and atomic.
         *
         * Returns:
         *  The result of an atomicLoad of val immediately following the increment operation.  This value
         *  is not required to be equal to the newly stored value.  Thus, competing writes are allowed to
         *  occur between the increment and successive load operation.
         */
        template decrement( msync ms : msync.none ) { T decrement() { return atomicDecrement!(ms,T)( m_val ); } }
        template decrement( msync ms : msync.ssb )  { T decrement() { return atomicDecrement!(ms,T)( m_val ); } } /// ditto
        template decrement( msync ms : msync.acq )  { T decrement() { return atomicDecrement!(ms,T)( m_val ); } } /// ditto
        template decrement( msync ms : msync.rel )  { T decrement() { return atomicDecrement!(ms,T)( m_val ); } } /// ditto
    }

private:
    T   m_val;
}


////////////////////////////////////////////////////////////////////////////////
// Support Code for Unit Tests
////////////////////////////////////////////////////////////////////////////////


private
{
    template testLoad( msync ms, T )
    {
        void testLoad( T val = T.init + 1 )
        {
            T          base;
            Atomic!(T) atom;

            assert( atom.load!(ms)() == base );
            base        = val;
            atom.m_val  = val;
            assert( atom.load!(ms)() == base );
        }
    }


    template testStore( msync ms, T )
    {
        void testStore( T val = T.init + 1 )
        {
            T          base;
            Atomic!(T) atom;

            assert( atom.m_val == base );
            base = val;
            atom.store!(ms)( base );
            assert( atom.m_val == base );
        }
    }


    template testStoreIf( msync ms, T )
    {
        void testStoreIf( T val = T.init + 1 )
        {
            T          base;
            Atomic!(T) atom;

            assert( atom.m_val == base );
            base = val;
            atom.storeIf!(ms)( base, val );
            assert( atom.m_val != base );
            atom.storeIf!(ms)( base, T.init );
            assert( atom.m_val == base );
        }
    }


    template testIncrement( msync ms, T )
    {
        void testIncrement( T val = T.init + 1 )
        {
            T          base = val;
            T          incr = val;
            Atomic!(T) atom;

            atom.m_val = val;
            assert( atom.m_val == base && incr == base );
            base = base + 1;
            incr = atom.increment!(ms)();
            assert( atom.m_val == base && incr == base );
        }
    }


    template testDecrement( msync ms, T )
    {
        void testDecrement( T val = T.init + 1 )
        {
            T          base = val;
            T          decr = val;
            Atomic!(T) atom;

            atom.m_val = val;
            assert( atom.m_val == base && decr == base );
            base = base - 1;
            decr = atom.decrement!(ms)();
            assert( atom.m_val == base && decr == base );
        }
    }


    template testType( T )
    {
        void testType( T val = T.init  +1 )
        {
            testLoad!(msync.none, T)( val );
            testLoad!(msync.acq, T)( val );

            testStore!(msync.none, T)( val );
            testStore!(msync.acq, T)( val );
            testStore!(msync.rel, T)( val );

            testStoreIf!(msync.none, T)( val );
            testStoreIf!(msync.acq, T)( val );

            static if( isValidNumericType!(T) )
            {
                testIncrement!(msync.none, T)( val );
                testIncrement!(msync.acq, T)( val );

                testDecrement!(msync.none, T)( val );
                testDecrement!(msync.acq, T)( val );
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


unittest
{
    testType!(bool)();

    testType!(byte)();
    testType!(ubyte)();

    testType!(short)();
    testType!(ushort)();

    testType!(int)();
    testType!(uint)();

    int x;
    testType!(void*)( &x );

    //
    // long
    //

    version( X86_64 )
    {
        testLoad!(msync.none, long)();
        testLoad!(msync.acq, long)();

        testStore!(msync.none, long)();
        testStore!(msync.acq, long)();
        testStore!(msync.rel, long)();

        testIncrement!(msync.none, long)();
        testDecrement!(msync.acq, long)();
    }
    version( X86 )
    {
        testStoreIf!(msync.none, long)();
        testStoreIf!(msync.acq, long)();
    }

    //
    // ulong
    //

    version( X86_64 )
    {
        testLoad!(msync.none, ulong)();
        testLoad!(msync.acq, ulong)();

        testStore!(msync.none, ulong)();
        testStore!(msync.acq, ulong)();
        testStore!(msync.rel, ulong)();

        testIncrement!(msync.none, ulong)();
        testDecrement!(msync.acq, ulong)();
    }
    version( X86 )
    {
        testStoreIf!(msync.none, ulong)();
        testStoreIf!(msync.acq, ulong)();
    }
}