/** Arbitrary precision arithmetic ('bignum') for processors with no asm support
  *
 * All functions operate on arrays of uints, stored LSB first.
 * If there is a destination array, it will be the first parameter.
 * Currently, all of these functions are subject to change, and are
 * intended for internal use only.
 * This module is intended only to assist development of high-speed routines
 * on currently unsupported processors.
 *
 * Author: Don Clugston
 * Date: May 2008.
 *
 * License: Public Domain
 */

module tango.math.impl.BignumNoAsm;

public:
/** Multi-byte addition or subtraction
 *    dest[] = src1[] + src2[] + carry (0 or 1).
 * or dest[] = src1[] - src2[] - carry (0 or 1).
 * Returns carry or borrow (0 or 1).
 * Set op == '+' for addition, '-' for subtraction.
 */
uint multibyteAddSub(char op)(uint[] dest, uint [] src1, uint [] src2, uint carry)
{
    ulong c = carry;
    for (uint i = 0; i < src2.length; ++i) {
        static if (op=='+') c = c  + src1[i] + src2[i];
             else c = cast(ulong)src1[i] - src2[i] - c;
        dest[i] = c & 0xFFFF_FFFF;
        c = (c>0xFFFF_FFFF);
//        c >>>=32;
//        assert(c==0 || c==1);
    }
    return c;
}

unittest
{
    uint [] a = new uint[40];
    uint [] b = new uint[40];
    uint [] c = new uint[40];
    for (int i=0; i<a.length; ++i)
    {
        if (i&1) a[i]=0x8000_0000 + i;
        else a[i]=i;
        b[i]= 0x8000_0003;
    }
    c[19]=0x3333_3333;
    uint carry = multibyteAddSub!('+')(c[0..18], b[0..18], a[0..18], 0);
    assert(c[0]==0x8000_0003);
    assert(c[1]==4);
    assert(c[19]==0x3333_3333); // check for overrun
    assert(carry==1);
    for (int i=0; i<a.length; ++i)
    {
        a[i]=b[i]=c[i]=0;
    }
    a[8]=0x048D159E;
    b[8]=0x048D159E;
    a[10]=0x1D950C84;
    b[10]=0x1D950C84;
    a[5] =0x44444444;
    carry = multibyteAddSub!('-')(a[0..12], a[0..12], b[0..12], 0);
    assert(a[11]==0);
    for (int i=0; i<10; ++i) if (i!=5) assert(a[i]==0); 
    
    for (int q=3; q<36;++q) {
        for (int i=0; i<a.length; ++i)
        {
            a[i]=b[i]=c[i]=0;
        }    
        a[q-2]=0x040000;
        b[q-2]=0x040000;
       carry = multibyteAddSub!('-')(a[0..q], a[0..q], b[0..q], 0);
       assert(a[q-2]==0);
    }
}



/** dest[] += carry, or dest[] -= carry.
 *  op must be '+' or '-'
 *  Returns final carry or borrow (0 or 1)
 */
uint multibyteIncrement(char op)(uint[] dest, uint carry)
{
    static if (op=='+') {
        ulong c = carry;
        c += dest[0];
        dest[0] = c & 0xFFFF_FFFF;
        if (c<=0xFFFF_FFFF) return 0; 
        
        for (uint i = 1; i < dest.length; ++i) {
            ++dest[i];
            if (dest[i]!=0) return 0;
        }
        return 1;
   } else {
       ulong c = carry;
       c = dest[0] - c;
       dest[0] = c & 0xFFFF_FFFF;
       if (c<=0xFFFF_FFFF) return 0;
        for (uint i = 1; i < dest.length; ++i) {
            --dest[i];
            if (dest[i]!=0xFFFF_FFFF) return 0;
        }
        return 1;
    }
}

enum LogicOp : byte { AND, OR, XOR };

/** Dest[] = src1[] op src2[]
*   where op == AND,OR, or XOR
*/
void multibyteLogical(LogicOp op)(uint [] dest, uint [] src1, uint [] src2)
{
    for (int i=0; i<dest.length;++i) {
        static if (op==LogicOp.AND) dest[i] = src1[i] & src2[i];
        else static if (op==LogicOp.OR) dest[i] = src1[i] | src2[i];
        else dest[i] = src1[i] ^ src2[i];
    }
}

unittest
{
    uint [] bb = [0x0F0F_0F0F, 0xF0F0_F0F0, 0x0F0F_0F0F, 0xF0F0_F0F0];
    for (int qqq=0; qqq<3; ++qqq) {
        uint [] aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];    
        
        switch(qqq) {
        case 0:
            multibyteLogical!(LogicOp.AND)(aa[1..3], aa[1..3], bb[0..4]);
            assert(aa[1]==0x0202_0203 && aa[2]==0x4050_5050 && aa[3]== 0x8999_999A);
            break;
        case 1:
            multibyteLogical!(LogicOp.OR)(aa[1..2], aa[1..2], bb[0..3]);
            assert(aa[1]==0x1F2F_2F2F && aa[2]==0x4555_5556 && aa[3]== 0x8999_999A);
            break;
        case 2:
            multibyteLogical!(LogicOp.XOR)(aa[1..2], aa[1..2], bb[0..3]);
            assert(aa[1]==0x1D2D_2D2C && aa[2]==0x4555_5556 && aa[3]== 0x8999_999A);
            break;
        default:
            assert(0);
        }
        
        assert(aa[0]==0xF0FF_FFFF);
    }
}

/** dest[] = src[] << numbits
 *  numbits must be in the range 1..31
 */
void multibyteShl(uint [] dest, uint [] src, uint numbits)
{
    ulong c = 0;
    for(int i=0; i<dest.length; ++i){
        c += (cast(ulong)(src[i]) << numbits);
        dest[i] = c & 0xFFFF_FFFF;
        c >>>= 32;
   }
}


/** dest[] = src[] >> numbits
 *  numbits must be in the range 1..31
 */
void multibyteShr(uint [] dest, uint [] src, uint numbits)
{
    ulong c = 0;
    for(int i=dest.length-1; i>=0; --i){
        c += (src[i] >>numbits) + (cast(ulong)(src[i]) << (64 - numbits));
        dest[i]= c & 0xFFFF_FFFF;
        c >>>= 32;
   }
}

unittest
{
    
    uint [] aa = [0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteShr(aa[0..$-2], aa, 4);
	assert(aa[0]==0x6122_2222 && aa[1]==0xA455_5555 && aa[2]==0x0899_9999);
	assert(aa[3]==0xBCCC_CCCD);

    aa = [0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteShr(aa[0..$-1], aa, 4);
	assert(aa[0] == 0x6122_2222 && aa[1]==0xA455_5555 
	    && aa[2]==0xD899_9999 && aa[3]==0x0BCC_CCCC);

    aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteShl(aa[1..4], aa[1..$], 4);
	assert(aa[0] == 0xF0FF_FFFF && aa[1] == 0x2222_2230 
	    && aa[2]==0x5555_5561 && aa[3]==0x9999_99A4 && aa[4]==0x0BCCC_CCCD);
}

/** dest[] = src[] * multiplier + carry.
 * Returns carry.
 */
uint multibyteMul(uint[] dest, uint[] src, uint multiplier, uint carry)
{
    ulong c = carry;
    for(int i=0; i<src.length; ++i){
        c += cast(ulong)(src[i]) * multiplier;
        dest[i] = c & 0xFFFF_FFFF;
        c>>=32;
    }
    return c;
}

unittest
{
    uint [] aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteMul(aa[1..4], aa[1..4], 16, 0);
	assert(aa[0] == 0xF0FF_FFFF && aa[1] == 0x2222_2230 && aa[2]==0x5555_5561 && aa[3]==0x9999_99A4 && aa[4]==0x0BCCC_CCCD);
}

/**
 * dest[] += src[] * multiplier + carry(0..FFFF_FFFF).
 * Returns carry out of MSB (0..FFFF_FFFF).
 */
uint multibyteMulAdd(uint [] dest, uint[] src, uint multiplier, uint carry)
{
    assert(dest.length==src.length);
    ulong c = carry;
    for(int i=0; i<src.length; ++i){
        c = c + cast(ulong)(src[i]) * multiplier + dest[i];
        dest[i] = c & 0xFFFF_FFFF;
        c>>=32;
    }
    return c;    
}

unittest {
    
    uint [] aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    uint [] bb = [0x1234_1234, 0xF0F0_F0F0, 0x00C0_C0C0, 0xF0F0_F0F0, 0xC0C0_C0C0];
    multibyteMulAdd(bb[1..$-1], aa[1..$-2], 16, 5);
	assert(bb[0] == 0x1234_1234 && bb[4] == 0xC0C0_C0C0);
    assert(bb[1] == 0x2222_2230 + 0xF0F0_F0F0+5 && bb[2] == 0x5555_5561+0x00C0_C0C0+1
	    && bb[3] == 0x9999_99A4+0xF0F0_F0F0 );
}

/** 
   Sets result = result[0..left.length] + left * right
   
   It is defined in this way to allow cache-efficient multiplication.
   This function is equivalent to:
    ----
    for (int i = 0; i< right.length; ++i) {
        dest[left.length + i] = multibyteMulAdd(dest[i..left.length+i],
                left, right[i], 0);
    }
    ----
 */
void multibyteMultiplyAccumulate(uint [] dest, uint[] left, uint [] right)
{
    for (int i = 0; i< right.length; ++i) {
        dest[left.length + i] = multibyteMulAdd(dest[i..left.length+i],
                left, right[i], 0);
    }
}

/**  dest[] /= divisor.
 * overflow is the initial remainder, and must be in the range 0..divisor-1.
 */
uint multibyteDiv(uint [] dest, uint divisor, uint overflow)
{
    ulong c = cast(ulong)overflow;
    for(int i=dest.length-1; i>=0; --i){
        c = (c<<32) + cast(ulong)(dest[i]);
        ulong q = c/divisor;
        c -= divisor*q;
        dest[i] = q;
    }
    return c;

}

unittest {
    uint [] aa = new uint[101];
    for (int i=0; i<aa.length; ++i) aa[i] = 0x8765_4321 * (i+3);
    uint overflow = multibyteMul(aa, aa, 0x8EFD_FCFB, 0x33FF_7461);
    uint r = multibyteDiv(aa, 0x8EFD_FCFB, overflow);
    for (int i=aa.length-1; i>=0; --i) { assert(aa[i] == 0x8765_4321 * (i+3)); }
    assert(r==0x33FF_7461);

}
