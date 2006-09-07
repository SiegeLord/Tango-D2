/*
 * Author:
 *  Walter Bright
 * Copyright:
 *  Copyright (c) 2001-2005 by Digital Mars,
 *  All Rights Reserved,
 *  www.digitalmars.com
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  <ul>
 *  <li> The origin of this software must not be misrepresented; you must not
 *       claim that you wrote the original software. If you use this software
 *       in a product, an acknowledgment in the product documentation would be
 *       appreciated but is not required.
 *  </li>
 *  <li> Altered source versions must be plainly marked as such, and must not
 *       be misrepresented as being the original software.
 *  </li>
 *  <li> This notice may not be removed or altered from any source
 *       distribution.
 *  </li>
 *  </ul>
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 *  Additional functions added by Don Clugston
 */

/**
 * Macros:
 *
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *  SVH3 = $(TR $(TH $1) $(TH $2) $(TH $3))
 *  SV3  = $(TR $(TD $1) $(TD $2) $(TD $3))
 *  NAN = $(RED NAN)
 */
module tango.math.IEEE;

static import tango.stdc.math;

private {
/* Constants describing the storage of a IEEE floating-point types
 * These values will differ depending on whether 'real' is 64, 80, or 128 bits,
 * and whether it is a big-endian or little-endian architecture.
 */
template float_traits(T)
{
    static if (T.mant_dig == 53) {
        // IEEE double (64 bits)
        const uint mant_bytes = 7;
        typedef ulong mant_type;
        typedef uint exp_type;
     version (LittleEndian) {
        const uint mant_offset = 0;
        const int exp_offset = 1;
        const ulong mant_mask = 0x000F_FFFF_FFFF_FFFF;
        const uint exp_mask = 0x7FF0_0000;
    }
        const bool has_implied_bit = false;
    } else static if (T.mant_dig == 64) {
        // IEEE double extended (80-bits)
        const uint mant_bytes = 8;
        typedef ulong mant_type;
        typedef ushort exp_type;
     version (LittleEndian) {
        const uint mant_offset = 0;
        const int exp_offset = 4;
        const ulong mant_mask = 0xFFFF_FFFF_FFFF_FFFF;
        const ulong exp_mask = 0x7FFF;
     }
        const bool has_implied_bit = true;
    } else static assert(0, "Unsupported floating point size - must be 64 or 80 bits");
}

}

// Returns true if equal to precision, false if not
// (This function is used in unit tests)
package bool mfeq(real x, real y, real precision)
{
    if (x == y)
        return true;
    if (isNaN(x) || isNaN(y))
        return false;
    return fabs(x - y) <= precision;
}

/**
 * Returns x rounded to a long value using the FE_TONEAREST rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */
extern (C) real rndtonl(real x);

/**
 * Separate floating point value into significand and exponent.
 *
 * Returns:
 *  Calculate and return <i>x</i> and exp such that
 *  value =<i>x</i>*2$(SUP exp) and
 *  .5 &lt;= |<i>x</i>| &lt; 1.0<br>
 *  <i>x</i> has same sign as value.
 *
 *  $(TABLE_SV
 *  <tr> <th> value          <th> returns        <th> exp
 *  <tr> <td> &plusmn;0.0    <td> &plusmn;0.0    <td> 0
 *  <tr> <td> +&infin;       <td> +&infin;       <td> int.max
 *  <tr> <td> -&infin;       <td> -&infin;       <td> int.min
 *  <tr> <td> &plusmn;$(NAN) <td> &plusmn;$(NAN) <td> int.min
 *  )
 */
real frexp(real value, out int exp)
{
    ushort* vu = cast(ushort*)&value;
    long* vl = cast(long*)&value;
    uint ex;

    // If exponent is non-zero
    ex = vu[4] & 0x7FFF;
    if (ex)
    {
    if (ex == 0x7FFF)
    {   // infinity or NaN
        if (*vl &  0x7FFFFFFFFFFFFFFF)  // if NaN
        {   *vl |= 0xC000000000000000;  // convert $(NAN)S to $(NAN)Q
        exp = int.min;
        }
        else if (vu[4] & 0x8000)
        {   // negative infinity
        exp = int.min;
        }
        else
        {   // positive infinity
        exp = int.max;
        }
    }
    else
    {
        exp = ex - 0x3FFE;
        vu[4] = cast(ushort)((0x8000 & vu[4]) | 0x3FFE);
    }
    }
    else if (!*vl)
    {
    // value is +-0.0
    exp = 0;
    }
    else
    {   // denormal
    int i = -0x3FFD;

    do
    {
        i--;
        *vl <<= 1;
    } while (*vl > 0);
    exp = i;
        vu[4] = cast(ushort)((0x8000 & vu[4]) | 0x3FFE);
    }
    return value;
}

unittest
{
    static real vals[][3] = // x,frexp,exp
    [
    [0.0,   0.0,    0],
    [-0.0,  -0.0,   0],
    [1.0,   .5, 1],
    [-1.0,  -.5,    1],
    [2.0,   .5, 2],
    [155.67e20, 0x1.A5F1C2EB3FE4Fp-1,   74],    // normal
    [1.0e-320,  0.98829225,     -1063],
    [real.min,  .5,     -16381],
    [real.min/2.0L, .5,     -16382],    // denormal

    [real.infinity,real.infinity,int.max],
    [-real.infinity,-real.infinity,int.min],
    [real.nan,real.nan,int.min],
    [-real.nan,-real.nan,int.min],

    // Don't really support signalling nan's in D
    //[real.nans,real.nan,int.min],
    //[-real.nans,-real.nan,int.min],
    ];
    int i;

    for (i = 0; i < vals.length; i++)
    {
    real x = vals[i][0];
    real e = vals[i][1];
    int exp = cast(int)vals[i][2];
    int eptr;
    real v = frexp(x, eptr);

    //printf("frexp(%Lg) = %.8Lg, should be %.8Lg, eptr = %d, should be %d\n", x, v, e, eptr, exp);
    assert(mfeq(e, v, .0000001));
    assert(exp == eptr);
    }
}

/**
 * Compute n * 2$(SUP exp)
 * References: frexp
 */
real ldexp(real n, int exp) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fild exp;
            fld n;
            fscale;
        }
    }
    else
    {
        return tango.stdc.math.ldexpl(n, exp);
    }
}

/**
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is not a special value, the result is the same as
 * <tt>cast(int)logb(x)</tt>.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th>ilogb(x)     <th> Range error?
 *  <tr> <td> 0               <td> FP_ILOGB0   <td> yes
 *  <tr> <td> &plusmn;&infin; <td> +&infin;    <td> no
 *  <tr> <td> $(NAN)          <td> FP_ILOGBNAN <td> no
 *  )
 */
int ilogb(real x)
{
    return tango.stdc.math.ilogbl(x);
}

alias tango.stdc.math.FP_ILOGB0   FP_ILOGB0;
alias tango.stdc.math.FP_ILOGBNAN FP_ILOGBNAN;

/**
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is subnormal, it is treated as if it were normalized.
 * For a positive, finite x:
 *
 * -----
 * 1 <= $(I x) * FLT_RADIX$(SUP -logb(x)) < FLT_RADIX
 * -----
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> logb(x)  <th> Divide by 0?
 *  <tr> <td> &plusmn;&infin; <td> +&infin; <td> no
 *  <tr> <td> &plusmn;0.0     <td> -&infin; <td> yes
 *  )
 */
real logb(real x)
{
    return tango.stdc.math.logbl(x);
}

/**
 * Efficiently calculates x * 2$(SUP n).
 *
 * scalbn handles underflow and overflow in
 * the same fashion as the basic arithmetic operators.
 *
 *  $(TABLE_SV
 *  <tr> <th> x                <th> scalb(x)
 *  <tr> <td> &plusmn;&infin; <td> &plusmn;&infin;
 *  <tr> <td> &plusmn;0.0      <td> &plusmn;0.0
 *  )
 */
real scalbn(real x, int n)
{
    // BUG: Not implemented in DMD
    return tango.stdc.math.scalbnl(x, n);
}

/**
 * Returns the positive difference between x and y.
 *
 * Returns:
 * $(TABLE_SV
 *  $(SVH Arguments, fdim(x, y))
 *  $(SV x &gt; y, x - y)
 *  $(SV x &lt;= y, +0.0)
 * )
 */
real fdim(real x, real y)
{
    return (x > y) ? x - y : +0.0;
}

/**
 * Returns |x|
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> fabs(x)
 *  <tr> <td> &plusmn;0.0     <td> +0.0
 *  <tr> <td> &plusmn;&infin; <td> +&infin;
 *  )
 */
real fabs(real x) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fabs;
        }
    }
    else
    {
        return tango.stdc.math.fabsl(x);
    }
}

/**
 * Returns (x * y) + z, rounding only once according to the
 * current rounding mode.
 */
real fma(real x, real y, real z)
{
    return (x * y) + z;
}

/**
 * Calculate cos(y) + i sin(y).
 *
 * On x86 CPUs, this is a very efficient operation;
 * almost twice as fast as calculating sin(y) and cos(y)
 * seperately, and is the preferred method when both are required.
 */
creal expi(ireal y)
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld y;
            fsincos;
            fxch st(1), st(0);
        }
    }
    else
    {
        return tango.stdc.math.cosl(y.im) + tango.stdc.math.sinl(y.im)*1i;
    }
}

unittest
{
    assert(expi(1.3e5Li)==tango.stdc.math.cosl(1.3e5L) + tango.stdc.math.sinl(1.3e5L)*1i);
    assert(expi(0.0Li)==1L+0.0Li);
}

/*********************************
 * Returns !=0 if e is a NaN.
 */

int isNaN(real e)
{
    ushort* pe = cast(ushort *)&e;
    ulong*  ps = cast(ulong *)&e;

    return (pe[4] & 0x7FFF) == 0x7FFF &&
        *ps & 0x7FFFFFFFFFFFFFFF;
}

unittest
{
    assert(isNaN(float.nan));
    assert(isNaN(-double.nan));
    assert(isNaN(real.nan));

    assert(!isNaN(53.6));
    assert(!isNaN(float.infinity));
}


/**
 * Returns !=0 if x is normalized.
 *
 * (Need one for each format because subnormal
 *  floats might be converted to normal reals)
 */
int isNormal(float x)
{
    uint *p = cast(uint *)&x;
    uint e;

    e = *p & 0x7F800000;
    //printf("e = x%x, *p = x%x\n", e, *p);
    return e && e != 0x7F800000;
}

/** ditto */
int isNormal(double d)
{
    uint *p = cast(uint *)&d;
    uint e;

    e = p[1] & 0x7FF00000;
    return e && e != 0x7FF00000;
}

/** ditto */
int isNormal(real e)
{
    ushort* pe = cast(ushort *)&e;
    long*   ps = cast(long *)&e;

    return (pe[4] & 0x7FFF) != 0x7FFF && *ps < 0;
}

unittest
{
    float f = 3;
    double d = 500;
    real e = 10e+48;

    assert(isNormal(f));
    assert(isNormal(d));
    assert(isNormal(e));
}

/*********************************
 * Is the binary representation of x identical to y?
 *
 * Same as ==, except that positive and negative zero are not identical,
 * and two $(NAN)s are identical if they have the same 'payload'.
 */

bool isIdentical(real x, real y)
{
    ushort* pxe = cast(ushort *)&x;
    long*   pxs = cast(long *)&x;
    ushort* pye = cast(ushort *)&y;
    long*   pys = cast(long *)&y;
    return pxe[4]==pye[4] && pxs[0]==pys[0];
}

unittest {
    assert(isIdentical(0.0, 0.0));
    assert(!isIdentical(0.0, -0.0));
    assert(isIdentical(makeNaN("abc"), makeNaN("abc")));
    assert(!isIdentical(makeNaN("abc"), makeNaN("xyz")));
    assert(isIdentical(1.234e56, 1.234e56));
    assert(isNaN(makeNaN("abcdefghijklmn")));
}

/*********************************
 * Is number subnormal? (Also called "denormal".)
 * Subnormals have a 0 exponent and a 0 most significant mantissa bit.
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int isSubnormal(float f)
{
    uint *p = cast(uint *)&f;

    //printf("*p = x%x\n", *p);
    return (*p & 0x7F800000) == 0 && *p & 0x007FFFFF;
}

unittest
{
    float f = 3.0;

    for (f = 1.0; !isSubnormal(f); f /= 2)
    assert(f != 0);
}

/// ditto

int isSubnormal(double d)
{
    uint *p = cast(uint *)&d;

    return (p[1] & 0x7FF00000) == 0 && (p[0] || p[1] & 0x000FFFFF);
}

unittest
{
    double f;

    for (f = 1; !isSubnormal(f); f /= 2)
    assert(f != 0);
}

/// ditto

int isSubnormal(real e)
{
    ushort* pe = cast(ushort *)&e;
    long*   ps = cast(long *)&e;

    return (pe[4] & 0x7FFF) == 0 && *ps > 0;
}

unittest
{
    real f;

    for (f = 1; !isSubnormal(f); f /= 2)
    assert(f != 0);
}

/*********************************
 * Return !=0 if x is &plusmn;0.
 */
int isZero(real x)
{
    ushort* pe = cast(ushort *)&x;
    ulong*  ps = cast(ulong *)&x;
    return (pe[4]&0x7FFF) == 0 && *ps == 0;
}


/*********************************
 * Return !=0 if e is &plusmn;&infin;.
 */

int isInfinity(real e)
{
    ushort* pe = cast(ushort *)&e;
    ulong*  ps = cast(ulong *)&e;

    return (pe[4] & 0x7FFF) == 0x7FFF &&
        *ps == 0x8000000000000000;
}

unittest
{
    assert(isInfinity(float.infinity));
    assert(!isInfinity(float.nan));
    assert(isInfinity(double.infinity));
    assert(isInfinity(-real.infinity));

    assert(isInfinity(-1.0 / 0.0));
}


/**
 * Calculate the next largest floating point value after x.
 *
 * Return the least number greater than x that is representable as a real;
 * thus, it gives the next point on the IEEE number line.
 * This function is included in the forthcoming IEEE 754R standard.
 *
 *  $(TABLE_SV
 *    $(SVH x,             nextup(x)   )
 *    $(SV  -&infin;,      -real.max   )
 *    $(SV  &plusmn;0.0,   real.min*real.epsilon )
 *    $(SV  real.max,      real.infinity )
 *    $(SV  real.infinity, real.infinity )
 *    $(SV  $(NAN),        $(NAN)        )
 * )
 */
real nextUp(real x)
{
    ushort *pe = cast(ushort *)&x;
    ulong *ps = cast(ulong *)&x;

    if ((pe[4] & 0x7FFF) == 0x7FFF) {
        // First, deal with NANs and infinity
        if (x == -real.infinity) return -real.max;
        return x; // +INF and NAN are unchanged.
    }
    if (pe[4] & 0x8000)  { // Negative number -- need to decrease the mantissa
        --*ps;
        // Need to mask with 0x7FFF... so denormals are treated correctly.
        if ((*ps & 0x7FFFFFFFFFFFFFFF) == 0x7FFFFFFFFFFFFFFF) {
            if (pe[4] == 0x8000) { // it was negative zero
//                *ps = 1;  pe[4] = 0;
                return real.min*real.epsilon; // smallest subnormal.
            }
            --pe[4];
            if (pe[4] == 0x8000) {
                return x; // it's become a denormal, implied bit stays low.
            }
            *ps = 0xFFFFFFFFFFFFFFFF; // set the implied bit
            return x;
        }
        return x;
    } else {
        // Positive number -- need to increase the mantissa.
        // Works automatically for positive zero.
        ++*ps;
        if ((*ps & 0x7FFFFFFFFFFFFFFF) == 0) {
            // change in exponent
            ++pe[4];
            *ps = 0x8000000000000000; // set the high bit
        }
    }
    return x;
}

unittest {
    assert( isNaN(nextUp(real.nan)));
    // negative numbers
    assert( nextUp(-real.infinity) == -real.max );
    assert( nextUp(-1-real.epsilon) == -1.0 );
    assert( nextUp(-2) == -2.0 + real.epsilon);
    // denormals and zero
    assert( nextUp(-real.min) == -real.min*(1-real.epsilon) );
    assert( nextUp(-real.min*(1-real.epsilon) == -real.min*(1-2*real.epsilon)) );
    real z  = nextUp(-real.min*(1-real.epsilon) );
    assert( isIdentical(-0.0L, nextUp(-real.min*real.epsilon)) );
    assert( nextUp(-0.0) == real.min*real.epsilon );
    assert( nextUp(0.0) == real.min*real.epsilon );
    assert( nextUp(real.min*(1-real.epsilon)) == real.min );
    assert( nextUp(real.min) == real.min*(1+real.epsilon) );
    // positive numbers
    assert( nextUp(1) == 1.0 + real.epsilon );
    assert( nextUp(2.0-real.epsilon) == 2.0 );
    assert( nextUp(real.max) == real.infinity );
    assert( nextUp(real.infinity)==real.infinity );
}

/**
 * Calculate the next smallest floating point value after x.
 *
 * Return the greatest number less than x that is representable as a real;
 * thus, it gives the previous point on the IEEE number line.
 * This function is included in the forthcoming IEEE 754R standard.
 *
 * Special values:
 * real.infinity   real.max
 * real.min*real.epsilon 0.0
 * 0.0             -real.min*real.epsilon
 * -0.0            -real.min*real.epsilon
 * -real.max        -real.infinity
 * -real.infinity    -real.infinity
 * NAN              NAN
 */
real nextDown(real x)
{
    return -nextUp(-x);
}

unittest {
    assert( nextDown(1.0 + real.epsilon) == 1.0);
}

/**
 * Calculates the next representable value after x in the direction of y.
 *
 * If y > x, the result will be the next largest floating-point value;
 * if y < x, the result will be the next smallest value.
 * If x == y, the result is y.
 *
 * Remarks:
 * This function is not generally very useful; it's almost always better to use
 * the faster functions nextup() or nextdown() instead.
 *
 * Not implemented:
 * The FE_INEXACT and FE_OVERFLOW exceptions will be raised if x is finite and
 * the function result is infinite. The FE_INEXACT and FE_UNDERFLOW
 * exceptions will be raised if the function value is subnormal, and x is
 * not equal to y.
 */
real nextafter(real x, real y)
{
    if (x==y) return y;
    return (y>x) ? nextUp(x) : nextDown(x);

    // BUG: Not implemented in DMD
//    return tango.stdc.math.nextafterl(x, y);
}


/**************************************
 * To what precision is x equal to y?
 *
 * Returns: the number of mantissa bits which are equal in x and y.
 * eg, 0x1.F8p+60 and 0x1.F1p+60 are equal to 5 bits of precision.
 *
 *  $(TABLE_SV
 *    $(SVH3 x,      y,         feqrel(x, y)  )
 *    $(SV3  x,      x,         real.mant_dig )
 *    $(SV3  x,      &gt;= 2*x, 0 )
 *    $(SV3  x,      &lt;= x/2, 0 )
 *    $(SV3  $(NAN), any,       0 )
 *    $(SV3  any,    $(NAN),    0 )
 *  )
 *
 * Remarks:
 * This is a very fast operation, suitable for use in speed-critical code.
 *
 */

int feqrel(real x, real y)
{
    /* Public Domain. Author: Don Clugston, 18 Aug 2005.
     */

    if (x == y) return real.mant_dig; // ensure diff!=0, cope with INF.

    real diff = fabs(x - y);

    ushort *pa = cast(ushort *)(&x);
    ushort *pb = cast(ushort *)(&y);
    ushort *pd = cast(ushort *)(&diff);

    // The difference in abs(exponent) between x or y and abs(x-y)
    // is equal to the number of mantissa bits of x which are
    // equal to y. If negative, x and y have different exponents.
    // If positive, x and y are equal to 'bitsdiff' bits.
    // AND with 0x7FFF to form the absolute value.
    // To avoid out-by-1 errors, we subtract 1 so it rounds down
    // if the exponents were different. This means 'bitsdiff' is
    // always 1 lower than we want, except that if bitsdiff==0,
    // they could have 0 or 1 bits in common.
    int bitsdiff = ( ((pa[4]&0x7FFF) + (pb[4]&0x7FFF)-1)>>1) - pd[4];

    if (pd[4] == 0)
    {   // Difference is denormal
        // For denormals, we need to add the number of zeros that
        // lie at the start of diff's mantissa.
        // We do this by multiplying by 2^real.mant_dig
        diff *= 0x1p+63;
        return bitsdiff + real.mant_dig - pd[4];
    }

    if (bitsdiff > 0)
        return bitsdiff + 1; // add the 1 we subtracted before

    // Avoid out-by-1 errors when factor is almost 2.
    return (bitsdiff == 0) ? (pa[4] == pb[4]) : 0;
}

unittest
{
   // Exact equality
   assert(feqrel(real.max,real.max)==real.mant_dig);
   assert(feqrel(0,0)==real.mant_dig);
   assert(feqrel(7.1824,7.1824)==real.mant_dig);
   assert(feqrel(real.infinity,real.infinity)==real.mant_dig);

   // a few bits away from exact equality
   real w=1;
   for (int i=1; i<real.mant_dig-1; ++i) {
      assert(feqrel(1+w*real.epsilon,1)==real.mant_dig-i);
      assert(feqrel(1-w*real.epsilon,1)==real.mant_dig-i);
      assert(feqrel(1,1+(w-1)*real.epsilon)==real.mant_dig-i+1);
      w*=2;
   }
   assert(feqrel(1.5+real.epsilon,1.5)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5+real.epsilon)==real.mant_dig-2);

   // Numbers that are close
   assert(feqrel(0x1.Bp+84, 0x1.B8p+84)==5);
   assert(feqrel(0x1.8p+10, 0x1.Cp+10)==2);
   assert(feqrel(1.5*(1-real.epsilon), 1)==2);
   assert(feqrel(1.5, 1)==1);
   assert(feqrel(2*(1-real.epsilon), 1)==1);

   // Factors of 2
   assert(feqrel(real.max,real.infinity)==0);
   assert(feqrel(2*(1-real.epsilon), 1)==1);
   assert(feqrel(1, 2)==0);
   assert(feqrel(4, 1)==0);

   // Extreme inequality
   assert(feqrel(real.nan,real.nan)==0);
   assert(feqrel(0,-real.nan)==0);
   assert(feqrel(real.nan,real.infinity)==0);
   assert(feqrel(real.infinity,-real.infinity)==0);
   assert(feqrel(-real.max,real.infinity)==0);
   assert(feqrel(real.max,-real.max)==0);
}


/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */

int signbit(real e)
{
    ubyte* pe = cast(ubyte *)&e;

//printf("e = %Lg\n", e);
    return (pe[9] & 0x80) != 0;
}

unittest
{
    debug (math) printf("math.signbit.unittest\n");
    assert(!signbit(float.nan));
    assert(signbit(-float.nan));
    assert(!signbit(168.1234));
    assert(signbit(-168.1234));
    assert(!signbit(0.0));
    assert(signbit(-0.0));
}

/*********************************
 * Return a value composed of to with from's sign bit.
 */

real copysign(real to, real from)
{
    ubyte* pto   = cast(ubyte *)&to;
    ubyte* pfrom = cast(ubyte *)&from;

    pto[9] &= 0x7F;
    pto[9] |= pfrom[9] & 0x80;

    return to;
}

unittest
{
    real e;

    e = copysign(21, 23.8);
    assert(e == 21);

    e = copysign(-21, 23.8);
    assert(e == 21);

    e = copysign(21, -23.8);
    assert(e == -21);

    e = copysign(-21, -23.8);
    assert(e == -21);

    e = copysign(real.nan, -23.8);
    assert(isNaN(e) && signbit(e));
}

// Functions for NaN payloads

/**
 * Returns true if x has a char [] payload.
 * Returns false if x is not a NaN, or has an integral payload.
 */
bool isNaNPayloadString(real x)
{
    ushort* px = cast(ushort *)(&x);
    return (px[4] & 0x7FFF == 0x7FFF) && (px[3] & 0x4000 == 0x4000);
}

/**
 *  Make a NaN with a string payload.
 *
 * Storage space in the payload is strictly limited. Only the low 7 bits of
 * each character are stored in the payload, and at most 8 characters can be
 * stored.
 */
real makeNaN(char [] str)
{
    ulong v = 7; // implied bit, then signalling bit, then 1 for string NaN
    int n = str.length;

    if (n>8) n=8;
    for (int i=0; i < n; ++i) {
        v <<= 7;
        v |= (str[i] & 0x7F);
        if (i==6) {
            v <<=1;
        }
    }
    for (int i=n; i < 8; ++i) {
        v <<=7;
        if (i==7) v<<=1;
    }
    v <<=4;

    real x = real.nan;
    *cast(ulong *)(&x) = v;
    return x;
}

/**
 * Extracts the character payload and stores the first buff.length
 * characters into it. The string is not null-terminated.
 * Returns the slice that was written to.
 */
char [] getNaNPayloadString(real x, char[] buff)
{
    assert(isNaNPayloadString(x));
    ulong m = *cast(ulong *)(&x);
    // Skip implicit bit, quiet bit, and character bit
    m &= 0x1FFF_FFFF_FFFF_FFFF;
    m <<= 2; // Move the first byte to the top
    ulong q;
    int i=0;
    while (m!=0 && i< buff.length) {
        q =( m & 0x7F00_0000_0000_0000);
        m -= q;
        m <<= 7;
        if (i==6) m <<=1;
        q >>>= 7*8;
        buff[i] = cast(ubyte)q;
        ++i;
    }
    return buff[0..i];
}
