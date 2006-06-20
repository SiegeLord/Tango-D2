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
 */

module tango.math.core;

private import tango.stdc.math;
private import tango.math.ieee;

/*
 * Constants
 */

const real E          = 2.7182818284590452354L;  /** e */
const real LOG2T      = 0x1.a934f0979a3715fcp+1; /** log<sub>2</sub>10 */ // 3.32193 fldl2t
const real LOG2E      = 0x1.71547652b82fe178p+0; /** log<sub>2</sub>e */ // 1.4427 fldl2e
const real LOG2       = 0x1.34413509f79fef32p-2; /** log<sub>10</sub>2 */ // 0.30103 fldlg2
const real LOG10E     = 0.43429448190325182765;  /** log<sub>10</sub>e */
const real LN2        = 0x1.62e42fefa39ef358p-1; /** ln 2 */    // 0.693147 fldln2
const real LN10       = 2.30258509299404568402;  /** ln 10 */
const real PI         = 0x1.921fb54442d1846ap+1; /** &pi; */ // 3.14159 fldpi
const real PI_2       = 1.57079632679489661923;  /** &pi; / 2 */
const real PI_4       = 0.78539816339744830962;  /** &pi; / 4 */
const real M_1_PI     = 0.31830988618379067154;  /** 1 / &pi; */
const real M_2_PI     = 0.63661977236758134308;  /** 2 / &pi; */
const real M_2_SQRTPI = 1.12837916709551257390;  /** 2 / &radic;&pi; */
const real SQRT2      = 1.41421356237309504880;  /** &radic;2 */
const real SQRT1_2    = 0.70710678118654752440;  /** &radic;&frac12 */

/*
 * Primitives
 */

/**
 * Calculates the absolute value
 *
 * For complex numbers, abs(z) = sqrt( $(POWER z.re, 2) + $(POWER z.im, 2) )
 * = hypot(z.re, z.im).
 */
real abs(real x)
{
    return tango.math.ieee.fabs(x);
}

/** ditto */
long abs(long x)
{
    return x>=0 ? x : -x;
}

/** ditto */
int abs(int x)
{
    return x>=0 ? x : -x;
}

/** ditto */
real abs(creal z)
{
    return hypot(z.re, z.im);
}

/** ditto */
real abs(ireal y)
{
    return tango.math.ieee.fabs(y.im);
}

unittest
{
    assert(isPosZero(abs(-0.0L)));
    assert(isnan(abs(real.nan)));
    assert(abs(-real.infinity) == real.infinity);
    assert(abs(-3.2Li) == 3.2L);
    assert(abs(71.6Li) == 71.6L);
    assert(abs(-56) == 56);
    assert(abs(2321312L)  == 2321312L);
    assert(abs(-1+1i) == sqrt(2.0));
}

/**
 * Complex conjugate
 *
 *  conj(x + iy) = x - iy
 *
 * Note that z * conj(z) = $(POWER z.re, 2) - $(POWER z.im, 2)
 * is always a real number
 */
creal conj(creal z)
{
    return z.re - z.im*1i;
}

/** ditto */
ireal conj(ireal y)
{
    return -y;
}

unittest
{
    assert(conj(7 + 3i) == 7-3i);
    ireal z = -3.2Li;
    assert(conj(z) == -z);
}

/*
 * Trig Functions
 */

/**
 * Returns cosine of x. x is in radians.
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)               $(TH cos(x)) $(TH invalid?)  )
 *  $(TR $(TD $(NAN))          $(TD $(NAN)) $(TD yes)   )
 *  $(TR $(TD &plusmn;&infin;) $(TD $(NAN)) $(TD yes)   )
 *  )
 * Bugs:
 *  Results are undefined if |x| >= $(POWER 2,64).
 */
real cos(real x) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fcos;
        }
    }
    else
    {
        return tango.stdc.math.cosl(x);
    }
}

/**
 * Returns sine of x. x is in radians.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> sin(x)      <th>invalid?
 *  <tr> <td> $(NAN)          <td> $(NAN)      <td> yes
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;0.0 <td> no
 *  <tr> <td> &plusmn;&infin; <td> $(NAN)      <td> yes
 *  )
 * Bugs:
 *  Results are undefined if |x| >= $(POWER 2,64).
 */
real sin(real x) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fsin;
        }
    }
    else
    {
        return tango.stdc.math.sinl(x);
    }
}


/**
 * Returns tangent of x. x is in radians.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> tan(x)      <th> invalid?
 *  <tr> <td> $(NAN)          <td> $(NAN)      <td> yes
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;0.0 <td> no
 *  <tr> <td> &plusmn;&infin; <td> $(NAN)      <td> yes
 *  )
 */
real tan(real x)
{
    asm
    {
    fld x[EBP]          ; // load theta
    fxam                ; // test for oddball values
    fstsw   AX          ;
    sahf                ;
    jc  trigerr         ; // x is NAN, infinity, or empty
                          // 387's can handle denormals
SC18:   fptan           ;
    fstp    ST(0)       ; // dump X, which is always 1
    fstsw   AX          ;
    sahf                ;
    jnp Lret            ; // C2 = 1 (x is out of range)

    // Do argument reduction to bring x into range
    fldpi               ;
    fxch                ;
SC17:   fprem1          ;
    fstsw   AX          ;
    sahf                ;
    jp  SC17            ;
    fstp    ST(1)       ; // remove pi from stack
    jmp SC18            ;

trigerr:
    fstp    ST(0)       ; // dump theta
    }
    return real.nan;

Lret:
    ;
}

unittest
{
    static real vals[][2] = // angle,tan
    [
        [   0,   0],
        [   .5,  .5463024898],
        [   1,   1.557407725],
        [   1.5, 14.10141995],
        [   2,  -2.185039863],
        [   2.5,-.7470222972],
        [   3,  -.1425465431],
        [   3.5, .3745856402],
        [   4,   1.157821282],
        [   4.5, 4.637332055],
        [   5,  -3.380515006],
        [   5.5,-.9955840522],
        [   6,  -.2910061914],
        [   6.5, .2202772003],
        [   10,  .6483608275],

        // special angles
        [   PI_4,   1],
        //[ PI_2,   real.infinity],
        [   3*PI_4, -1],
        [   PI, 0],
        [   5*PI_4, 1],
        //[ 3*PI_2, -real.infinity],
        [   7*PI_4, -1],
        [   2*PI,   0],

        // overflow
        [   real.infinity,  real.nan],
        [   real.nan,   real.nan],
        [   1e+100,     real.nan],
    ];
    int i;

    for (i = 0; i < vals.length; i++)
    {
    real x = vals[i][0];
    real r = vals[i][1];
    real t = tan(x);

    //printf("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
    assert(mfeq(r, t, .0000001));

    x = -x;
    r = -r;
    t = tan(x);
    //printf("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
    assert(mfeq(r, t, .0000001));
    }
}

/**
 * Calculates the arc cosine of x,
 * returning a value ranging from -&pi;/2 to &pi;/2.
 *
 *  $(TABLE_SV
 *      <tr> <th> x        <th> acos(x) <th> invalid?
 *      <tr> <td> &gt;1.0  <td> $(NAN)  <td> yes
 *      <tr> <td> &lt;-1.0 <td> $(NAN)  <td> yes
 *      <tr> <td> $(NAN)   <td> $(NAN)  <td> yes
 *      )
 */
real acos(real x)
{
    return tango.stdc.math.acosl(x);
}

/**
 * Calculates the arc sine of x,
 * returning a value ranging from -&pi;/2 to &pi;/2.
 *
 *  $(TABLE_SV
 *  <tr> <th> x        <th> asin(x)  <th> invalid?
 *  <tr> <td> &plusmn;0.0    <td> &plusmn;0.0    <td> no
 *  <tr> <td> &gt;1.0  <td> $(NAN)   <td> yes
 *  <tr> <td> &lt;-1.0 <td> $(NAN)   <td> yes
 *       )
 */
real asin(real x)
{
    return tango.stdc.math.asinl(x);
}

/**
 * Calculates the arc tangent of x,
 * returning a value ranging from -&pi;/2 to &pi;/2.
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> atan(x)  <th> invalid?
 *  <tr> <td> &plusmn;0.0       <td> &plusmn;0.0    <td> no
 *  <tr> <td> &plusmn;&infin;  <td> $(NAN)   <td> yes
 *       )
 */
real atan(real x)
{
    return tango.stdc.math.atanl(x);
}

/**
 * Calculates the arc tangent of y / x,
 * returning a value ranging from -&pi;/2 to &pi;/2.
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> y         <th> atan(x, y)
 *  <tr> <td> $(NAN)      <td> anything  <td> $(NAN)
 *  <tr> <td> anything    <td> $(NAN)    <td> $(NAN)
 *  <tr> <td> &plusmn;0.0       <td> &gt; 0.0  <td> &plusmn;0.0
 *  <tr> <td> &plusmn;0.0       <td> &plusmn;0.0     <td> &plusmn;0.0
 *  <tr> <td> &plusmn;0.0       <td> &lt; 0.0  <td> &plusmn;&pi;
 *  <tr> <td> &plusmn;0.0       <td> -0.0      <td> &plusmn;&pi;
 *  <tr> <td> &gt; 0.0    <td> &plusmn;0.0     <td> &pi;/2
 *  <tr> <td> &lt; 0.0    <td> &plusmn;0.0     <td> &pi;/2
 *  <tr> <td> &gt; 0.0    <td> &infin;  <td> &plusmn;0.0
 *  <tr> <td> &plusmn;&infin;  <td> anything  <td> &plusmn;&pi;/2
 *  <tr> <td> &gt; 0.0    <td> -&infin; <td> &plusmn;&pi;
 *  <tr> <td> &plusmn;&infin;  <td> &infin;  <td> &plusmn;&pi;/4
 *  <tr> <td> &plusmn;&infin;  <td> -&infin; <td> &plusmn;3&pi;/4
 *      )
 */
real atan2(real x, real y)
{
    return tango.stdc.math.atan2l(x,y);
}

/**
 * Calculates the hyperbolic cosine of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x                <th> cosh(x)     <th> invalid?
 *  <tr> <td> &plusmn;&infin;  <td> &plusmn;0.0 <td> no
 *      )
 */
real cosh(real x)
{
    return tango.stdc.math.coshl(x);
}

/**
 * Calculates the hyperbolic sine of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> sinh(x)         <th> invalid?
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;0.0     <td> no
 *  <tr> <td> &plusmn;&infin; <td> &plusmn;&infin; <td> no
 *      )
 */
real sinh(real x)
{
    return tango.stdc.math.sinhl(x);
}

/**
 * Calculates the hyperbolic tangent of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> tanh(x)      <th> invalid?
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;0.0  <td> no
 *  <tr> <td> &plusmn;&infin; <td> &plusmn;1.0  <td> no
 *      )
 */
real tanh(real x)
{
    return tango.stdc.math.tanhl(x);
}

/**
 * Calculates the inverse hyperbolic cosine of x.
 *
 *  Mathematically, acosh(x) = log(x + sqrt( x*x - 1))
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN 1..&infin;)
 *  $(RANGE  1..log(real.max), &infin;) )
 *  $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  <1,     $(NAN) )
 *    $(SV  1,      0       )
 *    $(SV  +&infin;,+&infin;)
 *  )
 */
real acosh(real x)
{
    if (x > 1/real.epsilon)
    return LN2 + log(x);
    else
    return log(x + sqrt(x*x - 1));
}

unittest
{
    assert(isnan(acosh(0.9)));
    assert(isnan(acosh(real.nan)));
    assert(acosh(1)==0.0);
    assert(acosh(real.infinity) == real.infinity);
}

/**
 * Calculates the inverse hyperbolic sine of x.
 *
 *  Mathematically,
 *  ---------------
 *  asinh(x) =  log( x + sqrt( x*x + 1 )) // if x >= +0
 *  asinh(x) = -log(-x + sqrt( x*x + 1 )) // if x <= -0
 *  -------------
 *
 *  $(TABLE_SV
 *    $(SVH  x,             asinh(x)       )
 *    $(SV  $(NAN),         $(NAN)         )
 *    $(SV  &plusmn;0,      &plusmn;0      )
 *    $(SV  &plusmn;&infin;,&plusmn;&infin;)
 *  )
 */
real asinh(real x)
{
    if (tango.math.ieee.fabs(x) > 1 / real.epsilon) // beyond this point, x*x + 1 == x*x
    return copysign(LN2 + log(tango.math.ieee.fabs(x)), x);
    else
    {
    // sqrt(x*x + 1) ==  1 + x * x / ( 1 + sqrt(x*x + 1) )
    return copysign(log1p(tango.math.ieee.fabs(x) + x*x / (1 + sqrt(x*x + 1)) ), x);
    }
}

unittest
{
    assert(isPosZero(asinh(0.0)));
    assert(isNegZero(asinh(-0.0)));
    assert(asinh(real.infinity) == real.infinity);
    assert(asinh(-real.infinity) == -real.infinity);
    assert(isnan(asinh(real.nan)));
}

/**
 * Calculates the inverse hyperbolic tangent of x,
 * returning a value from ranging from -1 to 1.
 *
 * Mathematically, atanh(x) = log( (1+x)/(1-x) ) / 2
 *
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN -&infin;..&infin;)
 *  $(RANGE  -1..1) )
 *  $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  &plusmn;0, &plusmn;0)
 *    $(SV  -&infin;, -0)
 *  )
 */
real atanh(real x)
{
    // log( (1+x)/(1-x) ) == log ( 1 + (2*x)/(1-x) )
    return  0.5 * log1p( 2 * x / (1 - x) );
}

unittest
{
    assert(isPosZero(atanh(0.0)));
    assert(isNegZero(atanh(-0.0)));
    assert(isnan(atanh(real.nan)));
    assert(isNegZero(atanh(-real.infinity)));
}

/*
 * Powers and Roots
 */

/**
 * Compute square root of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x        <th> sqrt(x)  <th> invalid?
 *  <tr> <td> -0.0     <td> -0.0     <td> no
 *  <tr> <td> &lt;0.0  <td> $(NAN)   <td> yes
 *  <tr> <td> +&infin; <td> +&infin; <td> no
 *  )
 */
float sqrt(float x) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fsqrt;
        }
    }
    else
    {
        return tango.stdc.math.sqrtf(x);
    }
}

double sqrt(double x) /* intrinsic */ /// ditto
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fsqrt;
        }
    }
    else
    {
        return tango.stdc.math.sqrt(x);
    }
}

real sqrt(real x) /* intrinsic */ /// ditto
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld x;
            fsqrt;
        }
    }
    else
    {
        return tango.stdc.math.sqrtl(x);
    }
}

creal sqrt(creal z) /// ditto
{
    creal c;
    real x,y,w,r;

    if (z == 0)
    {
    c = z;
    }
    else
    {   real z_re = z.re;
    real z_im = z.im;

    x = tango.math.ieee.fabs(z_re);
    y = tango.math.ieee.fabs(z_im);
    if (x >= y)
    {
        r = y / x;
        w = sqrt(x) * sqrt(0.5 * (1 + sqrt(1 + r * r)));
    }
    else
    {
        r = x / y;
        w = sqrt(y) * sqrt(0.5 * (r + sqrt(1 + r * r)));
    }

    if (z_re >= 0)
    {
        c = w + (z_im / (w + w)) * 1.0i;
    }
    else
    {
        if (z_im < 0)
        w = -w;
        c = z_im / (w + w) + w * 1.0i;
    }
    }
    return c;
}

/**
 * Calculates the cube root x.
 *
 *  $(TABLE_SV
 *  <tr> <th> <i>x</i>  <th> cbrt(x)    <th> invalid?
 *  <tr> <td> &plusmn;0.0   <td> &plusmn;0.0    <td> no
 *  <tr> <td> $(NAN)    <td> $(NAN)     <td> yes
 *  <tr> <td> &plusmn;&infin;   <td> &plusmn;&infin; <td> no
 *  )
 */
real cbrt(real x)
{
    return tango.stdc.math.cbrtl(x);
}

/**
 * Calculates e$(SUP x).
 *
 *  $(TABLE_SV
 *  <tr> <th> x        <th> exp(x)
 *  <tr> <td> +&infin; <td> +&infin;
 *  <tr> <td> -&infin; <td> +0.0
 *  )
 */
real exp(real x)
{
    return tango.stdc.math.expl(x);
}

/**
 * Calculates the value of the natural logarithm base (e)
 * raised to the power of x, minus 1.
 *
 * For very small x, expm1(x) is more accurate
 * than exp(x)-1.
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> e$(SUP x)-1
 *  <tr> <td> &plusmn;0.0 <td> &plusmn;0.0
 *  <tr> <td> +&infin;    <td> +&infin;
 *  <tr> <td> -&infin;    <td> -1.0
 *  )
 */
real expm1(real x)
{
    return tango.stdc.math.expm1l(x);
}

/**
 * Calculates 2$(SUP x).
 *
 *  $(TABLE_SV
 *  <tr> <th> x <th> exp2(x)
 *  <tr> <td> +&infin; <td> +&infin;
 *  <tr> <td> -&infin; <td> +0.0
 *  )
 */
real exp2(real x)
{
    return tango.stdc.math.exp2l(x);
}

/*
 * Powers and Roots
 */

/**
 * Calculate the natural logarithm of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> log(x)   <th> divide by 0? <th> invalid?
 *  <tr> <td> &plusmn;0.0 <td> -&infin; <td> yes          <td> no
 *  <tr> <td> &lt; 0.0    <td> $(NAN)   <td> no           <td> yes
 *  <tr> <td> +&infin;    <td> +&infin; <td> no           <td> no
 *  )
 */
real log(real x)
{
    return tango.stdc.math.logl(x);
}

/**
 *  Calculates the natural logarithm of 1 + x.
 *
 *  For very small x, log1p(x) will be more accurate than
 *  log(1 + x).
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> log1p(x)    <th> divide by 0? <th> invalid?
 *  <tr> <td> &plusmn;0.0 <td> &plusmn;0.0 <td> no           <td> no
 *  <tr> <td> -1.0        <td> -&infin;    <td> yes          <td> no
 *  <tr> <td> &lt;-1.0    <td> $(NAN)      <td> no           <td> yes
 *  <tr> <td> +&infin;    <td> -&infin;    <td> no           <td> no
 *  )
 */
real log1p(real x)
{
    return tango.stdc.math.log1pl(x);
}

/**
 * Calculates the base-2 logarithm of x:
 * log<sub>2</sub>x
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> log2(x)  <th> divide by 0? <th> invalid?
 *  <tr> <td> &plusmn;0.0 <td> -&infin; <td> yes          <td> no
 *  <tr> <td> &lt; 0.0    <td> $(NAN)   <td> no           <td> yes
 *  <tr> <td> +&infin;    <td> +&infin; <td> no           <td> no
 *  )
 */
real log2(real x)
{
    return tango.stdc.math.log2l(x);
}

/**
 * Calculate the base-10 logarithm of x.
 *
 *  $(TABLE_SV
 *  <tr> <th> x           <th> log10(x) <th> divide by 0? <th> invalid?
 *  <tr> <td> &plusmn;0.0 <td> -&infin; <td> yes          <td> no
 *  <tr> <td> &lt; 0.0    <td> $(NAN)   <td> no           <td> yes
 *  <tr> <td> +&infin;    <td> +&infin; <td> no           <td> no
 *  )
 */
real log10(real x)
{
    return tango.stdc.math.log10l(x);
}

/**
 * Fast integral powers.
 */
real pow(real x, uint n)
{
    real p;

    switch (n)
    {
    case 0:
        p = 1.0;
        break;

    case 1:
        p = x;
        break;

    case 2:
        p = x * x;
        break;

    default:
        p = 1.0;
        while (1)
        {
        if (n & 1)
            p *= x;
        n >>= 1;
        if (!n)
            break;
        x *= x;
        }
        break;
    }
    return p;
}

/** ditto */
real pow(real x, int n)
{
    if (n < 0)
    return pow(x, cast(real)n);
    else
    return pow(x, cast(uint)n);
}

/**
 * Calculates x$(SUP y).
 *
 * $(TABLE_SV
 * <tr>
 * <th> x <th> y <th> pow(x, y) <th> div 0 <th> invalid?
 * <tr>
 * <td> anything    <td> &plusmn;0.0    <td> 1.0    <td> no     <td> no
 * <tr>
 * <td> |x| &gt; 1  <td> +&infin;       <td> +&infin;   <td> no     <td> no
 * <tr>
 * <td> |x| &lt; 1  <td> +&infin;       <td> +0.0   <td> no     <td> no
 * <tr>
 * <td> |x| &gt; 1  <td> -&infin;       <td> +0.0   <td> no     <td> no
 * <tr>
 * <td> |x| &lt; 1  <td> -&infin;       <td> +&infin;   <td> no     <td> no
 * <tr>
 * <td> +&infin;    <td> &gt; 0.0       <td> +&infin;   <td> no     <td> no
 * <tr>
 * <td> +&infin;    <td> &lt; 0.0       <td> +0.0   <td> no     <td> no
 * <tr>
 * <td> -&infin;    <td> odd integer &gt; 0.0   <td> -&infin;   <td> no     <td> no
 * <tr>
 * <td> -&infin;    <td> &gt; 0.0, not odd integer  <td> +&infin;   <td> no     <td> no
 * <tr>
 * <td> -&infin;    <td> odd integer &lt; 0.0   <td> -0.0   <td> no     <td> no
 * <tr>
 * <td> -&infin;    <td> &lt; 0.0, not odd integer  <td> +0.0   <td> no     <td> no
 * <tr>
 * <td> &plusmn;1.0     <td> &plusmn;&infin;        <td> $(NAN)     <td> no     <td> yes
 * <tr>
 * <td> &lt; 0.0    <td> finite, nonintegral    <td> $(NAN)     <td> no     <td> yes
 * <tr>
 * <td> &plusmn;0.0     <td> odd integer &lt; 0.0   <td> &plusmn;&infin; <td> yes   <td> no
 * <tr>
 * <td> &plusmn;0.0     <td> &lt; 0.0, not odd integer  <td> +&infin;   <td> yes    <td> no
 * <tr>
 * <td> &plusmn;0.0     <td> odd integer &gt; 0.0   <td> &plusmn;0.0 <td> no    <td> no
 * <tr>
 * <td> &plusmn;0.0     <td> &gt; 0.0, not odd integer  <td> +0.0   <td> no     <td> no
 * )
 */
real pow(real x, real y)
{
    version (linux) // C pow() often does not handle special values correctly
    {
    if (isnan(y))
        return real.nan;

    if (y == 0)
        return 1;       // even if x is $(NAN)
    if (isnan(x) && y != 0)
        return real.nan;
    if (isinf(y))
    {
        if (tango.math.ieee.fabs(x) > 1)
        {
        if (signbit(y))
            return +0.0;
        else
            return real.infinity;
        }
        else if (tango.math.ieee.fabs(x) == 1)
        {
        return real.nan;
        }
        else // < 1
        {
        if (signbit(y))
            return real.infinity;
        else
            return +0.0;
        }
    }
    if (isinf(x))
    {
        if (signbit(x))
        {   long i;

        i = cast(long)y;
        if (y > 0)
        {
            if (i == y && i & 1)
            return -real.infinity;
            else
            return real.infinity;
        }
        else if (y < 0)
        {
            if (i == y && i & 1)
            return -0.0;
            else
            return +0.0;
        }
        }
        else
        {
        if (y > 0)
            return real.infinity;
        else if (y < 0)
            return +0.0;
        }
    }

    if (x == 0.0)
    {
        if (signbit(x))
        {   long i;

        i = cast(long)y;
        if (y > 0)
        {
            if (i == y && i & 1)
            return -0.0;
            else
            return +0.0;
        }
        else if (y < 0)
        {
            if (i == y && i & 1)
            return -real.infinity;
            else
            return real.infinity;
        }
        }
        else
        {
        if (y > 0)
            return +0.0;
        else if (y < 0)
            return real.infinity;
        }
    }
    }
    return tango.stdc.math.powl(x, y);
}

unittest
{
    real x = 46;

    assert(pow(x,0) == 1.0);
    assert(pow(x,1) == x);
    assert(pow(x,2) == x * x);
    assert(pow(x,3) == x * x * x);
    assert(pow(x,8) == (x * x) * (x * x) * (x * x) * (x * x));
}

/**
 * Calculates the length of the
 * hypotenuse of a right-angled triangle with sides of length x and y.
 * The hypotenuse is the value of the square root of
 * the sums of the squares of x and y:
 *
 *  sqrt(x&sup2; + y&sup2;)
 *
 * Note that hypot(x, y), hypot(y, x) and
 * hypot(x, -y) are equivalent.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> y           <th> hypot(x, y) <th> invalid?
 *  <tr> <td> x               <td> &plusmn;0.0 <td> |x|         <td> no
 *  <tr> <td> &plusmn;&infin; <td> y           <td> +&infin;    <td> no
 *  <tr> <td> &plusmn;&infin; <td> $(NAN)      <td> +&infin;    <td> no
 *  )
 */
real hypot(real x, real y)
{
    /*
     * This is based on code from:
     * Cephes Math Library Release 2.1:  January, 1989
     * Copyright 1984, 1987, 1989 by Stephen L. Moshier
     * Direct inquiries to 30 Frost Street, Cambridge, MA 02140
     */

    const int PRECL = 32;
    const int MAXEXPL = real.max_exp; //16384;
    const int MINEXPL = real.min_exp; //-16384;

    real xx, yy, b, re, im;
    int ex, ey, e;

    // Note, hypot(INFINITY, NAN) = INFINITY.
    if (isinf(x) || isinf(y))
    return real.infinity;

    if (isnan(x))
    return x;
    if (isnan(y))
    return y;

    re = tango.math.ieee.fabs(x);
    im = tango.math.ieee.fabs(y);

    if (re == 0.0)
    return im;
    if (im == 0.0)
    return re;

    // Get the exponents of the numbers
    xx = tango.math.ieee.frexp(re, ex);
    yy = tango.math.ieee.frexp(im, ey);

    // Check if one number is tiny compared to the other
    e = ex - ey;
    if (e > PRECL)
    return re;
    if (e < -PRECL)
    return im;

    // Find approximate exponent e of the geometric mean.
    e = (ex + ey) >> 1;

    // Rescale so mean is about 1
    xx = tango.math.ieee.ldexp(re, -e);
    yy = tango.math.ieee.ldexp(im, -e);

    // Hypotenuse of the right triangle
    b = sqrt(xx * xx  +  yy * yy);

    // Compute the exponent of the answer.
    yy = tango.math.ieee.frexp(b, ey);
    ey = e + ey;

    // Check it for overflow and underflow.
    if (ey > MAXEXPL + 2)
    {
    //return __matherr(_OVERFLOW, INFINITY, x, y, "hypotl");
    return real.infinity;
    }
    if (ey < MINEXPL - 2)
    return 0.0;

    // Undo the scaling
    b = tango.math.ieee.ldexp(b, e);
    return b;
}

unittest
{
    static real vals[][3] = // x,y,hypot
    [
    [   0,  0,  0],
    [   0,  -0, 0],
    [   3,  4,  5],
    [   -300,   -400,   500],
    [   real.min, real.min, 4.75473e-4932L],
    [   real.max/2, real.max/2, 0x1.6a09e667f3bcc908p+16383L /*8.41267e+4931L*/],
    [   real.infinity, real.nan, real.infinity],
    [   real.nan, real.nan, real.nan],
    ];
    int i;

    for (i = 0; i < vals.length; i++)
    {
    real x = vals[i][0];
    real y = vals[i][1];
    real z = vals[i][2];
    real h = hypot(x, y);

    //printf("hypot(%Lg, %Lg) = %Lg, should be %Lg\n", x, y, h, z);
    //if (!mfeq(z, h, .0000001))
        //printf("%La\n", h);
    assert(mfeq(z, h, .0000001));
    }
}

/**
 * Evaluate polynomial A(x) = a<sub>0</sub> + a<sub>1</sub>x + a<sub>2</sub>x&sup2; + a<sub>3</sub>x&sup3; ...
 *
 * Uses Horner's rule A(x) = a<sub>0</sub> + x(a<sub>1</sub> + x(a<sub>2</sub> + x(a<sub>3</sub> + ...)))
 * Params:
 *  A = array of coefficients a<sub>0</sub>, a<sub>1</sub>, etc.
 */
real poly(real x, real[] A)
in
{
    assert(A.length > 0);
}
body
{
    version (D_InlineAsm_X86)
    {
	version (Windows)
	{
    asm // assembler by W. Bright
    {
        // EDX = (A.length - 1) * real.sizeof
        mov     ECX,A[EBP]          ; // ECX = A.length
        dec     ECX                 ;
        lea     EDX,[ECX][ECX*8]    ;
        add     EDX,ECX             ;
        add     EDX,A+4[EBP]        ;
        fld     real ptr [EDX]      ; // ST0 = coeff[ECX]
        jecxz   return_ST           ;
        fld     x[EBP]              ; // ST0 = x
        fxch    ST(1)               ; // ST1 = x, ST0 = r
        align   4                   ;
    L2:     fmul    ST,ST(1)        ; // r *= x
        fld     real ptr -10[EDX]   ;
        sub     EDX,10              ; // deg--
        faddp   ST(1),ST            ;
        dec     ECX                 ;
        jne     L2                  ;
        fxch    ST(1)               ; // ST1 = r, ST0 = x
        fstp    ST(0)               ; // dump x
        align   4                   ;
    return_ST:                      ;
        ;
    }
    }
    else
    {
	    asm	// assembler by W. Bright
	    {
		// EDX = (A.length - 1) * real.sizeof
		mov     ECX,A[EBP]		    ; // ECX = A.length
		dec     ECX			        ;
		lea     EDX,[ECX*8]		    ;
		lea	EDX,[EDX][ECX*4]	    ;
		add     EDX,A+4[EBP]	    ;
		fld     real ptr [EDX]	    ; // ST0 = coeff[ECX]
		jecxz   return_ST		    ;
		fld     x[EBP]			    ; // ST0 = x
		fxch    ST(1)			    ; // ST1 = x, ST0 = r
		align   4			        ;
	L2:     fmul    ST,ST(1)		; // r *= x
		fld     real ptr -12[EDX]	;
		sub     EDX,12			    ; // deg--
		faddp   ST(1),ST		    ;
		dec     ECX			        ;
		jne     L2			        ;
		fxch    ST(1)			    ; // ST1 = r, ST0 = x
		fstp    ST(0)			    ; // dump x
		align   4			        ;
	return_ST:				        ;
		;
	    }
	}
    }
    else
    {
    int i = A.length - 1;
    real r = A[i];
    while (--i >= 0)
    {
        r *= x;
        r += A[i];
    }
    return r;
    }
}

unittest
{
    debug (math) printf("math.poly.unittest\n");
    real x = 3.1;
    static real pp[] = [56.1, 32.7, 6];

    assert( poly(x, pp) == (56.1L + (32.7L + 6L * x) * x) );
}

/*
 * Rounding (returning real)
 */

/**
 * Returns the value of x rounded downward to the next integer
 * (toward negative infinity).
 */
real floor(real x)
{
    return tango.stdc.math.floorl(x);
}

/**
 * Returns the value of x rounded upward to the next integer
 * (toward positive infinity).
 */
real ceil(real x)
{
    return tango.stdc.math.ceill(x);
}

/**
 * Return the value of x rounded to the nearest integer.
 * If the fractional part of x is exactly 0.5, the return value is rounded to
 * the even integer.
 */
real round(real x)
{
    return tango.stdc.math.roundl(x);
}

/**
 * Returns the integer portion of x, dropping the fractional portion.
 *
 * This is also known as "chop" rounding.
 */
real trunc(real x)
{
    return tango.stdc.math.truncl(x);
}

/**
* Rounds x to the nearest int or long.
*
* This is generally the fastest method to convert a floating-point number
* to an integer. Note that the results from this function
* depend on the rounding mode, if the fractional part of x is exactly 0.5.
* If using the default rounding mode (ties round to even integers)
* rndint(4.5) == 4, rndint(5.5)==6.
*/
int rndint(real x)
{
    version(D_InlineAsm_X86)
    {
        int n;
        asm
        {
            fld x;
            fistp n;
        }
        return n;
    }
    else
    {
        return tango.stdc.math.lrintl(x);
    }
}

/** ditto */
long rndlong(real x)
{
    version(D_InlineAsm_X86)
    {
        long n;
        asm
        {
            fld x;
            fistp n;
        }
        return n;
    }
    else
    {
        return tango.stdc.math.llrintl(x);
    }
}