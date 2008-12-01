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
 * All arithmetic operations are supported, except
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
	BigUint data;     // BigInt adds signed arithmetic to BigUint.
	bool sign = false;
public:
    /// Construct a BigInt from a decimal or hexadecimal string.
    /// The number must be in the form of a D decimal or hex literal:
    /// It may have a leading + or - sign; followed by "0x" if hexadecimal.
    /// Underscores are permitted.
    static BigInt opCall(char [] s) {
        BigInt r;
        if (s[0] == '-') {
            r.sign = true;
            s = s[1..$];
        } else if (s[0]=='+') {
            s = s[1..$];
        }
        auto q = 0X3;
        bool ok;
        if (s.length>2 && (s[0..2]=="0x" || s[0..2]=="0X")) {
            ok = r.data.fromHexString(s[2..$]);
        } else {
            ok = r.data.fromDecimalString(s);
        }
        assert(ok);
        return r;
    }
    ///
    void opAssign(T:int)(T x) {
        data = (x < 0) ? -x : x;
        sign = (x < 0);
    }
    ///
    BigInt opAdd(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        BigInt r;
        r.sign = sign;
        r.data = BigUint.addOrSubInt(data, u, sign!=(y<0), &r.sign);
        return r;
    }    
    ///
    BigInt opAddAssign(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        data = BigUint.addOrSubInt(data, u, sign!=(y<0), &sign);
        return *this;
    }    
    ///
    BigInt opAdd(T: BigInt)(T y) {
        BigInt r;
        r.sign = sign;
        r.data = BigUint.addOrSub(data, y.data, sign != y.sign, &r.sign);
        return r;
    }
    ///
    BigInt opAddAssign(T:BigInt)(T y) {
        data = BigUint.addOrSub(data, y.data, sign != y.sign, &sign);
        return *this;
    }    
    ///
    BigInt opSub(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        BigInt r;
        r.sign = sign;
        r.data = BigUint.addOrSubInt(data, u, sign == (y<0), &r.sign);
        return r;
    }        
    ///
    BigInt opSubAssign(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        data = BigUint.addOrSubInt(data, u, sign == (y<0), &sign);
        return *this;
    }
    ///
    BigInt opSub(T: BigInt)(T y) {
        BigInt r;
        r.sign = sign;
        r.data = BigUint.addOrSub(data, y.data, sign == y.sign, &r.sign);
        return r;
    }        
    ///
    BigInt opSubAssign(T:BigInt)(T y) {
        data = BigUint.addOrSub(data, y.data, sign == y.sign, &sign);
        return *this;
    }    
    ///
    BigInt opMul(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        return mulInternal(*this, u, sign != (y<0));
    }
    ///    
    BigInt opMulAssign(T: int)(T y) {
        ulong u = cast(ulong)(y < 0 ? -y : y);
        *this = mulInternal(*this, u, sign != (y<0));
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
    BigInt opDiv(T:int)(T y) {
        assert(y!=0, "Division by zero");
        BigInt r;
        uint u = y < 0 ? -y : y;
        r.data = BigUint.divInt(data, u);
        r.sign = r.isZero()? false : sign != (y<0);
        return r;
    }
    ///
    BigInt opDivAssign(T: int)(T y) {
        assert(y!=0, "Division by zero");
        uint u = y < 0 ? -y : y;
        data = BigUint.divInt(data, u);
        sign = data.isZero()? false : sign ^ (y<0);
        return *this;
    }
    ///
    BigInt opDivAssign(T: BigInt)(T y) {
        *this = divInternal(*this, y);
        return *this;
    }    
    ///
    BigInt opDiv(T: BigInt)(T y) {
        return divInternal(*this, y);
    }    
    ///
    int opMod(T:int)(T y) {
        assert(y!=0);
        uint u = y < 0 ? -y : y;
        int rem = BigUint.modInt(data, u);
        // x%y always has the same sign as x.
        // This is not the same as mathematical mod.
        return sign? -rem : rem; 
    }
    ///
    BigInt opModAssign(T:int)(T y) {
        assert(y!=0);
        uint u = y < 0 ? -y : y;
        data = BigUint.modInt(data, u);
        // x%y always has the same sign as x.
        // This is not the same as mathematical mod.
        return *this;
    }
    ///
    BigInt opMod(T: BigInt)(T y) {
        return modInternal(*this, y);
    }    
    ///
    BigInt opModAssign(T: BigInt)(T y) {
        *this = modInternal(*this, y);
        return *this;
    }    
    ///
    BigInt opNeg() {
        BigInt r = *this;
        r.negate();
        return r;
    }
    ///
    BigInt opPos() { return *this; }    
    ///
    BigInt opPostInc() {
        BigInt old = *this;
        data = BigUint.addOrSubInt(data, 1, false, &sign);
        return old;
    }
    ///
    BigInt opPostDec() {
        BigInt old = *this;
        data = BigUint.addOrSubInt(data, 1, true, &sign);
        return old;
    }
    ///
    BigInt opShr(T:int)(T y) {
        BigInt r;
        r.data = BigUint.shr(data, y);
        r.sign = r.data.isZero()? false : sign;
        return r;
    }
    ///
    BigInt opShrAssign(T:int)(T y) {
        data = BigUint.shr(data, y);
        if (data.isZero()) sign = false;
        return *this;
    }
    ///
    BigInt opShl(T:int)(T y) {
        BigInt r;
        r.data = BigUint.shl(data, y);
        r.sign = sign;
        return r;
    }
    ///
    BigInt opShlAssign(T:int)(T y) {
        data = BigUint.shl(data, y);
        return *this;
    }
    ///
    int opEquals(BigInt y) {
       return sign == y.sign && y.data == data;
    }
    ///
    int opCmp(T:int)(T y) {
     //   if (y==0) return sign? -1: 1;
        if (sign!=(y<0)) return sign ? -1 : 1;
        int cmp = BigUint.compare(data, y>=0? y: -y);        
        return sign? -cmp: cmp;
    }
    ///
    int opCmp(T:BigInt)(T y) {
        if (sign!=y.sign) return sign ? -1 : 1;
        int cmp = BigUint.compare(data, y.data);
        return sign? -cmp: cmp;
    }
public:
    /// BUG: For testing only, this will be removed eventually
    int numBytes() {
        return data.numBytes();
    }
    /// BUG: For testing only, this will be removed eventually
    char [] toDecimalString(){
        char [] buff = data.toDecimalString(1);
        if (isNegative()) buff[0] = '-';
        else buff = buff[1..$];
        return buff;
    }
    /// Convert to a hexadecimal string, with an underscore every
    /// 8 characters.
    char [] toHex() {
        char [] buff = data.toHexString(1, '_');
        if (isNegative()) buff[0] = '-';
        else buff = buff[1..$];
        return buff;
    }
private:
    void negate() { if (!data.isZero()) sign = !sign; }
    bool isZero() { return data.isZero(); }
    bool isNegative() { return sign; }

private:    
    static BigInt addsubInternal(BigInt x, BigInt y, bool wantSub) {
        BigInt r;
        r.sign = x.sign;
        r.data = BigUint.addOrSub(x.data, y.data, wantSub, &r.sign);
        return r;
    }
    static BigInt mulInternal(BigInt x, BigInt y) {
        BigInt r;        
        r.data = BigUint.mul(x.data, y.data);
        r.sign = r.isZero() ? false : x.sign ^ y.sign;
        return r;
    }
    
    static BigInt modInternal(BigInt x, BigInt y) {
        if (x.isZero()) return x;
        BigInt r;
        r.sign = x.sign;
        r.data = BigUint.mod(x.data, y.data);
        return r;
    }
    static BigInt divInternal(BigInt x, BigInt y) {
        if (x.isZero()) return x;
        BigInt r;
        r.sign = x.sign ^ y.sign;
        r.data = BigUint.div(x.data, y.data);
        return r;
    }
    static BigInt mulInternal(BigInt x, ulong y, bool negResult)
    {
        BigInt r;
        if (y==0) {
            r.sign = false;
            r.data = 0;
            return r;
        }
        r.sign = negResult;
        r.data = BigUint.mulInt(x.data, y);
        return r;
    }
}

debug(UnitTest)
{
unittest {
    // Radix conversion
    assert( BigInt("-1_234_567_890_123_456_789").toDecimalString 
        == "-1234567890123456789");
    assert( BigInt("0x1234567890123456789").toHex == "123_45678901_23456789");
    assert( BigInt("0x00000000000000000000000000000000000A234567890123456789").toHex
        == "A23_45678901_23456789");
    assert( BigInt("0x000_00_000000_000_000_000000000000_000000_").toHex == "0");

}
}