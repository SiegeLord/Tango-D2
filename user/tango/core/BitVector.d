/**
 * This module contains a packed bit array of fixed size, stack allocated arrays
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Fawzi Mohamed, derived from BitArray
 */
module tango.core.BitVector;
private import tango.core.BitManip;

alias uint internal_t; // at the moment there are places where this is hardcoded (bitsize=32)

struct BitVector(size_t len){
    internal_t[(len+internal_t.sizeof-1)/(internal_t.sizeof*8)] data;
    
    static BitVector opCall(bool[] vals){
        assert(vals.length==len);
        BitVector res;
        for (size_t i=0;i<len;++i){
            res[i]=vals[i];
        }
        return res;
    }
    
    internal_t *ptr(){
        return data.ptr;
    }
    
    size_t length(){
        return len;
    }
    
    size_t dim(){
        return data.length;
    }
    
    bool opIndex(size_t i){
        assert(i<len,"index out of bounds");
        return cast(bool)bt( data.ptr, i );
    }
    
    /**
     * Operates on all bits in this array.
     *
     * Params:
     *  dg = The supplied code as a delegate.
     */
    int opApply( int delegate(inout bool) dg )
    {
        int result;

        for( size_t i = 0; i < len; ++i )
        {
            bool b = opIndex( i );
            result = dg( b );
            opIndexAssign( b, i );
            if( result )
                break;
        }
        return result;
    }


    /** ditto */
    int opApply( int delegate(inout size_t, inout bool) dg )
    {
        int result;

        for( size_t i = 0; i < len; ++i )
        {
            bool b = opIndex( i );
            result = dg( i, b );
            opIndexAssign( b, i );
            if( result )
                break;
        }
        return result;
    }
    
    /**
     * returns a string with the hex representation of the current bit sequence
     */
    char[] toString(){
        auto dim = this.dim();
        char[] res;
        auto p=ptr;
        for (size_t i=0;i<dim;++i){
            for (int idim=internal_t.sizeof;idim!=0;){
                --idim;
                ubyte v=0xFF & (p[i]>>8*idim);
                ubyte v0=v & 0xF;
                v>>=4;
                auto str="0123456789ABCDEF";
                res~=str[v];
                res~=str[v0];
            }
        }
        return res;
    }


    /**
     * Compares this array to another for equality.  Two bit arrays are equal
     * if they are the same size and contain the same series of bits.
     *
     * Params:
     *  rhs = The array to compare against.
     *
     * Returns:
     *  zero if not equal and non-zero otherwise.
     */
    int opEquals( BitVector rhs )
    {
        uint* p1 = this.ptr;
        uint* p2 = rhs.ptr;
        size_t n = len / 32;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            if( p1[i] != p2[i] )
            return 0; // not equal
        }
        int rest = cast(int)(len & cast(size_t)31u);
        uint mask = ~((~0u)<<rest);
        return (rest == 0) || (p1[i] & mask) == (p2[i] & mask);
    }
    
    /**
     * returns a set with only one bit set (the first one)
     */
    BitVector singlify(){
        auto dim = this.dim();
        BitVector result;
        result.data[]=0;
        
        internal_t* p = this.ptr;
        size_t n = len / 32;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            if( p[i] != 0 ){
                result.data[i]=(cast(internal_t)1)<<bsr(p[i]);
                return result;
            }
        }
        int rest = cast(int)(len & cast(size_t)31u);
        uint mask = ~((~0u)<<rest);
        if (rest!=0 && (mask&p[n])!=0){
            result.ptr[n]=(cast(internal_t)1)<<bsr(p[n]);
        }
        return result;
    }

    /**
     * Performs a lexicographical comparison of this array to the supplied
     * array.
     *
     * Params:
     *  rhs = The array to compare against.
     *
     * Returns:
     *  A value less than zero if this array sorts before the supplied array,
     *  zero if the arrays are equavalent, and a value greater than zero if
     *  this array sorts after the supplied array.
     */
    int opCmp( BitVector rhs )
    {
        internal_t* p1 = this.ptr;
        internal_t* p2 = rhs.ptr;
        size_t n = len / 32;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            if( p1[i] != p2[i] ){
                return ((p1[i] < p2[i])?-1:1);
            }
        }
        int rest=cast(int)(len & cast(size_t) 31u);
        if (rest>0) {
            uint mask=~((~0u)<<rest);
            uint v1=p1[i] & mask;
            uint v2=p2[i] & mask;
            if (v1 != v2) return ((v1<v2)?-1:1);
        }
        return ((this.length<rhs.length)?-1:((this.length==rhs.length)?0:1));
    }


    /**
     * Convert this array to a void array.
     *
     * Returns:
     *  This array represented as a void array.
     */
    void[] opCast()
    {
        return cast(void[])ptr[0 .. dim];
    }


    /**
     * Generates a copy of this array with the unary complement operation
     * applied.
     *
     * Returns:
     *  A new array which is the complement of this array.
     */
    BitVector opCom()
    {
        auto dim = this.dim();
        BitVector result;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = ~this.ptr[i];
        if( len & 31 )
            result.ptr[dim - 1] &= ~(~0 << (len & 31));
        return result;
    }


    /**
     * Generates a new array which is the result of a bitwise and operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise and operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise and with this array and
     *  the supplied array.
     */
    BitVector opAnd( BitVector rhs )
    body
    {
        auto dim = this.dim();

        BitVector result;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] & rhs.ptr[i];
        return result;
    }


    /**
     * Generates a new array which is the result of a bitwise or operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise or operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise or with this array and
     *  the supplied array.
     */
    BitVector opOr( BitVector rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitVector result;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] | rhs.ptr[i];
        return result;
    }


    /**
     * Generates a new array which is the result of a bitwise xor operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise xor operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise xor with this array and
     *  the supplied array.
     */
    BitVector opXor( BitVector rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitVector result;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] ^ rhs.ptr[i];
        return result;
    }


    /**
     * Generates a new array which is the result of this array minus the
     * supplied array.  $(I a - b) for BitVectors means the same thing as
     * $(I a &amp; ~b).
     *
     * Params:
     *  rhs = The array with which to perform the subtraction operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of this array minus the supplied array.
     */
    BitVector opSub( BitVector rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitVector result;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] & ~rhs.ptr[i];
        return result;
    }


    /**
     * Support for index operations, much like the behavior of built-in arrays.
     *
     * Params:
     *  b   = The new bit value to set.
     *  pos = The desired index position.
     *
     * In:
     *  pos must be less than the length of this array.
     *
     * Returns:
     *  The new value of the bit at pos.
     */
    bool opIndexAssign( bool b, size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        if( b )
            bts( ptr, pos );
        else
            btr( ptr, pos );
        return b;
    }

    bool nonZero(){
        size_t i;
        for( i = 0; i < data.length; ++i )
        {
            if (data[i]) return true; 
        }
        return false;
/+        int rest=cast(int)(len & cast(size_t) (internal_t.sizeof*8-1));
        if (rest>0) {
            uint mask=~((~0u)<<rest);
            p1[i] = v & mask;
        }+/
    }
    
    /// assign a pattern to the whole array
    void opIndexAssign( internal_t v, size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        internal_t* p1 = this.ptr;
        size_t n = len / internal_t.sizeof;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            p1[i]=v;
        }
        int rest=cast(int)(len & cast(size_t) (internal_t.sizeof*8-1));
        if (rest>0) {
            uint mask=~((~0u)<<rest);
            p1[i] = v & mask;
        }
    }


    /**
     * Updates the contents of this array with the result of a bitwise and
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise and operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitVector opAndAssign( BitVector rhs )
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] &= rhs.ptr[i];
        return *this;
    }


    /**
     * Updates the contents of this array with the result of a bitwise or
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise or operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitVector opOrAssign( BitVector rhs )
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] |= rhs.ptr[i];
        return *this;
    }


    /**
     * Updates the contents of this array with the result of a bitwise xor
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise xor operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitVector opXorAssign( BitVector rhs )
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] ^= rhs.ptr[i];
        return *this;
    }


    /**
     * Updates the contents of this array with the result of this array minus
     * the supplied array.  $(I a - b) for BitVectors means the same thing as
     * $(I a &amp; ~b).
     *
     * Params:
     *  rhs = The array with which to perform the subtraction operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitVector opSubAssign( BitVector rhs )
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] &= ~rhs.ptr[i];
        return *this;
    }

}

debug( UnitTest )
{
  unittest
  {
    BitVector!(3) a = [1,0,1];

    int i;
    foreach( b; a )
    {
        switch( i )
        {
        case 0: assert( b == true );  break;
        case 1: assert( b == false ); break;
        case 2: assert( b == true );  break;
        default: assert( false );
        }
        i++;
    }

    foreach( j, b; a )
    {
        switch( j )
        {
        case 0: assert( b == true );  break;
        case 1: assert( b == false ); break;
        case 2: assert( b == true );  break;
        default: assert( false );
        }
    }
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) d = [1,0,1,1,1];
    BitVector!(5) e = [1,0,1,0,1];

    assert(e != d);
    assert(e == e);
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) d = [1,0,1,1,1];
    BitVector!(5) e = [1,0,1,0,1];

    assert( a <  d );
    assert( a <= d );
    assert( a == e );
    assert( a <= e );
    assert( a >= e );
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = ~a;

    assert(b[0] == 0);
    assert(b[1] == 1);
    assert(b[2] == 0);
    assert(b[3] == 1);
    assert(b[4] == 0);
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    BitVector!(5) c = a & b;

    assert(c[0] == 1);
    assert(c[1] == 0);
    assert(c[2] == 1);
    assert(c[3] == 0);
    assert(c[4] == 0);
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    BitVector!(5) c = a | b;

    assert(c[0] == 1);
    assert(c[1] == 0);
    assert(c[2] == 1);
    assert(c[3] == 1);
    assert(c[4] == 1);
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    BitVector!(5) c = a ^ b;

    assert(c[0] == 0);
    assert(c[1] == 0);
    assert(c[2] == 0);
    assert(c[3] == 1);
    assert(c[4] == 1);
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    BitVector!(5) c = a - b;

    assert( c[0] == 0 );
    assert( c[1] == 0 );
    assert( c[2] == 0 );
    assert( c[3] == 0 );
    assert( c[4] == 1 );
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    a &= b;
    assert( a[0] == 1 );
    assert( a[1] == 0 );
    assert( a[2] == 1 );
    assert( a[3] == 0 );
    assert( a[4] == 0 );
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    a |= b;
    assert( a[0] == 1 );
    assert( a[1] == 0 );
    assert( a[2] == 1 );
    assert( a[3] == 1 );
    assert( a[4] == 1 );
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    a ^= b;
    assert( a[0] == 0 );
    assert( a[1] == 0 );
    assert( a[2] == 0 );
    assert( a[3] == 1 );
    assert( a[4] == 1 );
  }
}

debug( UnitTest )
{
  unittest
  {
    BitVector!(5) a = [1,0,1,0,1];
    BitVector!(5) b = [1,0,1,1,0];

    a -= b;
    assert( a[0] == 0 );
    assert( a[1] == 0 );
    assert( a[2] == 0 );
    assert( a[3] == 0 );
    assert( a[4] == 1 );
  }
}
