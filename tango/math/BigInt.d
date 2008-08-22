/** Arbitrary-precision ('bignum') arithmetic
 *
 * Copyright: Copyright (C) 2008 Don Clugston.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 */

module tango.math.BigInt;

private import tango.math.internal.BiguintCore;

/** A struct representing an arbitrary precision integer
 *
 * All arithmetic and logical operations are supported, except
 * unsigned shift right (>>>).
 * It implements value semantics using copy-on-write. This means that
 * assignment is cheap, but operations such as x++ will cause heap
 * allocation. (But note that for most bigint operations, heap allocation is
 * inevitable anyway).
 *
 * Performance is excellent for numbers below ~1000 decimal digits.
 * For X86 machines, highly optimised assembly routines are used.
 */
struct BigInt
{
private:
	uint[] data = [0]; // In D2 this would be invariant(uint)[]
	bool sign;
    static uint [] ZERO = [0];
    static uint [] ONE = [1];
private:
    void assignUint(uint u) {
    	if (u==0) data = ZERO;
    	else if (u==1) data = ONE;
    	else {
    		data = new uint[1];
    		data[0] = u;
    	}
    }
public:
    ///
    void opAssign(T:int)(T x) {
        assignUint((x>=0)? x : -x);
        sign = (x<0);
    }
    ///
    BigInt opAdd(T: int)(T y) {
        return addsubInternal(*this, cast(ulong)(y<0? -y: y), sign!=(y<0));
    }    
    ///
    BigInt opAddAssign(T: int)(T y) {
        *this = addsubInternal(*this, cast(ulong)(y<0? -y: y), sign!=(y<0));
        return *this;
    }    
    ///
    BigInt opAdd(T:BigInt)(BigInt y) {
        return addsubInternal(*this, y, this.sign != y.sign);
    }
    ///
    BigInt opAddAssign(T:BigInt)(T y) {
        *this = addsubInternal(*this, y, this.sign != y.sign);
        return *this;
    }
    
    ///
    BigInt opSub(T: int)(T y) {
        return addsubInternal(*this, cast(ulong)(y<0? -y: y), sign==(y<0));
    }        
    ///
    BigInt opSubAssign(T: int)(T y) {
        *this = addsubInternal(*this, cast(ulong)(y<0? -y: y), sign==(y<0));
        return *this;
    }
    ///
    BigInt opSub(T: BigInt)(T y) {
        return addsubInternal(*this, y, this.sign == y.sign);
    }        
    ///
    BigInt opSubAssign(T:BigInt)(T y) {
        *this = addsubInternal(*this, y, this.sign == y.sign);
        return *this;
    }
    
    ///
    BigInt opMul(T: int)(T y) {
        return mulInternal(*this, cast(ulong)(y<0? -y: y), sign!=(y<0));
    }
    ///    
    BigInt opMulAssign(T: int)(T y) {
        *this = mulInternal(*this, cast(ulong)(y<0? -y: y), sign!=(y<0));
        return *this;
    }
    ///    
    BigInt opMul(T:BigInt)(T y) {
        return mulInternal(*this, y);
    }
    ///
    BigInt opMulAssign(T: BigInt)(T y) {
        *this = mulInternal(*this, y);
        return *this;        
    }
    ///
    BigInt opDivAssign(T: BigInt)(T y) {
        *this = divInternal(*this, y);
        return *this;
    }    
    ///
    BigInt opDiv(T: BigInt)(T y) {
        *this = divInternal(*this, y);
        return *this;
    }    
    ///
    BigInt opDiv(T:int)(T x) {
        assert(x!=0);
        BigInt r;
        uint u = x < 0 ? -x : x;
        r.data = biguintDivInt(data, u);
        r.sign = r.isZero()? false : this.sign != (x<0);
        return *this;        
    }
    ///
    int opMod(T:int)(T y) {
        assert(y!=0);
        uint u = y < 0 ? -y : y;
        int rem = biguintModInt(data, u);
        // x%y always has the same sign as x.
        // This is not the same as mathematical mod.
        return sign? -rem : rem; 
    }
    ///
    BigInt opDivAssign(T: int)(T x) {
        assert(x!=0);
        uint u = x < 0 ? -x : x;
    	data = biguintDivInt(data, u);
        sign = isZero()? false : sign ^ (x<0);
        return *this;
    }
    
    ///
    BigInt opNeg() { negate(); return *this; }
    ///
    BigInt opPos() { return *this; }    
    ///
    BigInt opPostInc() {
        BigInt old = *this;
        *this = addsubInternal(*this, 1, false);
        return old;
    }
    ///
    BigInt opPostDec() {
        BigInt old = *this;
        *this = addsubInternal(*this, 1, true);
        return old;
    }
    ///
    BigInt opShr(T:int)(T y) {
        BigInt r;
        r.data = biguintShr(this.data, y);
        r.sign = r.isZero()? false : sign;
        return r;
    }
    ///
    BigInt opShrAssign(T:int)(T y) {
        data = biguintShr(this.data, y);
        if (isZero()) sign = false;
        return *this;
    }
    ///
    BigInt opShl(T:int)(T y) {
        BigInt r;
        r.data = biguintShl(this.data, y);
        r.sign = sign;
        return r;
    }
    ///
    BigInt opShlAssign(T:int)(T y) {
        data = biguintShl(this.data, y);
        return *this;
    }
    ///
    int opEquals(BigInt y) {
       return sign == y.sign && y.data[] == data[];
    }
    ///
    int opCmp(BigInt y) {
        if (sign!=y.sign) return sign ? -1 : 1;
        if (data.length!=y.data.length) return data.length - y.data.length;
        return biguintCompare(data, y.data);
    }
public:
    /// BUG: For testing only, this will be removed eventually
    int numBytes() {
        return data.length * uint.sizeof;
    }
    /// BUG: For testing only, this will be removed eventually
    char [] toDecimalString(){
        uint predictlength = 20+20*(data.length/2); // just over 19
        char [] buff = new char[predictlength];
        int sofar = biguintToDecimal(buff, data.dup);
        if (isNegative()) {--sofar; buff[sofar]='-'; }
        
        return buff[sofar..$];
    }
    /// BUG: For testing only, this will be removed eventually
    void fromDecimalString(char [] s) {
        // Convert to base 10_000_000_000_000_000_000.
        // (this is the largest power of 10 that will fit into a long).
        // The length will be less than 1 + s.length/log2(10) = 1 + s.length/3.3219.
        // 485 bits will only just fit into 146 decimal digits.
        uint predictlength = (18*2 + 2* s.length)/19;
        data = new uint[predictlength];
        if (s[0]=='-') { sign=true; s=s[1..$]; }
        else sign = false;
        uint hi = biguintFromDecimal(data, s);
        data.length = hi;
        
    }
    char [] toHex() {
        int len = data.length*9;
        int start = 0;
        if (sign) {
            ++len;
            start = 1;
        }
        char [] buff = new char[len];
        if (sign) buff[0]='-';
        biguintToHex(buff[start..$], data,'_');
        return buff;
    }
    invariant() { assert(data.length==1 || data[$-1]!=0); }
private:
    void negate() { if (!isZero()) sign = !sign; }

    bool isZero() { return data.length==1 && data[0]==0; }
    bool isNegative() { return sign; }
private:
    static BigInt addsubInternal(BigInt x, BigInt y, bool wantSub) {
        BigInt r;
        if (wantSub) { // perform a subtraction
            bool bSign;
            r.data = biguintSub(x.data, y.data, &bSign);
            r.sign = x.sign^bSign;
            if (r.isZero()) { r.data = ZERO; r.sign = false; }
        } else {
            r.data = biguintAdd(x.data, y.data);
            r.sign = x.sign;
        }
        return r;
    }
    static BigInt addsubInternal(BigInt x, ulong y, bool wantSub) {
        BigInt r;
        r.sign = x.sign;
        if (wantSub) { // perform a subtraction
            if (x.data.length > 2) {
                r.data = biguintSubInt(x.data, y);                
            } else { // could change sign!
                ulong xx = x.data[0];
                if (x.data.length > 1) xx+= (cast(ulong)x.data[1]) << 32;
                ulong d;
                if (xx <= y) {
                    d = y - xx;
                    r.sign = !r.sign;
                } else {
                    d = xx - y;
                    r.sign = x.sign;
                }
                if (d==0) {
                    r.data = ZERO;
                    r.sign = false;
                    return r;
                }
                r.data = new uint[ d>uint.max ? 2: 1];
                r.data[0] = cast(uint)(d & 0xFFFF_FFFF);
                if (d>uint.max) r.data[1] = cast(uint)(d>>32);
            }
        } else {
            r.data = biguintAddInt(x.data, y);
        }
        return r;
    }
    static BigInt mulInternal(BigInt x, BigInt y) {
        uint len = x.data.length + y.data.length;
        BigInt r;
        r.data = new uint[len];
        r.sign = x.sign ^ y.sign;
        if (y.data.length > x.data.length) {
            biguintMul(r.data, y.data, x.data);
        } else {
            biguintMul(r.data, x.data, y.data);
        }
        // the highest element could be zero, 
        // in which case we need to reduce the length
        if (r.data.length > 1 && r.data[$-1] == 0) {
            r.data = r.data[0..$-1];
        }
        return r;
    }
    static BigInt divInternal(BigInt x, BigInt y) {
        if (x.isZero()) return x;
        BigInt r;
        r.sign = x.sign ^ y.sign;
        r.data = biguintDiv(x.data, y.data);
        return r;
    }
    static BigInt mulInternal(BigInt x, ulong y, bool negResult)
    {
        BigInt r;
        if (y==0) {
            r.sign=false;
            r.data = ZERO;
            return r;
        }
        r.sign = negResult;
        r.data = biguintMulInt(x.data, y);
        if (r.data.length > 1 && r.data[$-1] == 0) {
            r.data = r.data[0..$-1];
        }
        return r;
    }
}
