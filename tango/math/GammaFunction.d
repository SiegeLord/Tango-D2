/**
 * Implementation of lgamma() and tgamma()
 *
 * Copyright: Copyright (C) 2005-2006 Don Clugston,
 * Derived from C code in the Cephes library,
 * Copyright 1994 by Stephen L. Moshier
 *
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston, Stephen L. Moshier
 *
 *
Macros:
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *  GAMMA =  &#915;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  NAN = $(RED NAN)
 */
module tango.math.GammaFunction;
import tango.math.Core;
import tango.math.IEEE;

//------------------------------------------------------------------
private {

const real SQRT2PI = 2.50662827463100050242E0L; // sqrt(2pi)
// exp(gamma(x)) == inf if x>MAXGAMMA
const real MAXGAMMA = 1755.455L;

// Polynomial approximations for gamma and loggamma.

const real GammaNumeratorCoeffs[] = [
    0x1p+0,                  // 1
    0x1.acf42d903366539ep-1,     // 0.83780043015731267283
    0x1.73a991c8475f1aeap-2,     // 0.36295154366402391688
    0x1.c7e918751d6b2a92p-4,     // 0.1113062816019361559
    0x1.86d162cca32cfe86p-6,     // 0.023853632434611082525
    0x1.0c378e2e6eaf7cd8p-8,     // 0.0040926668283940355009
    0x1.dc5c66b7d05feb54p-12, // 0.00045429319606080091555
    0x1.616457b47e448694p-15     // 4.2127604874716220134e-05
];

const real GammaDenominatorCoeffs[] = [
    0x1p+0,                   // 1
    0x1.a8f9faae5d8fc8bp-2,   // 0.41501609505884554346
    -0x1.cb7895a6756eebdep-3,  // -0.22435109056703291645
    -0x1.7b9bab006d30652ap-5,  // -0.046338876712445342138
    0x1.c671af78f312082ep-6,      // 0.027737065658400729792
    -0x1.a11ebbfaf96252dcp-11, // -0.00079559336824947383209
    -0x1.447b4d2230a77ddap-10, // -0.0012377992466531522311
    0x1.ec1d45bb85e06696p-13,  // 0.00023465840591606352443
    -0x1.d4ce24d05bd0a8e6p-17  // -1.3971485174761704409e-05
];

const real SmallStirlingCoeffs[] = [
    0x1.55555555555543aap-4,      // 0.083333333333333318004
    0x1.c71c71c720dd8792p-9,      // 0.0034722222222300753277
    -0x1.5f7268f0b5907438p-9,  // -0.0026813271618763044182
    -0x1.e13cd410e0477de6p-13, // -0.00022947197478731854057
    0x1.9b0f31643442616ep-11,  // 0.00078403348427447530038
    0x1.2527623a3472ae08p-14,  // 6.9893322606231931717e-05
    -0x1.37f6bc8ef8b374dep-11, // -0.00059502375540563301557
    -0x1.8c968886052b872ap-16, // -2.3638488095017590616e-05
    0x1.76baa9c6d3eeddbcp-11      // 0.0007147391378143610789
];

const real LargeStirlingCoeffs[] = [
    1.0L,
    8.33333333333333333333E-2L,
    3.47222222222222222222E-3L,
    -2.68132716049382716049E-3L,
    -2.29472093621399176955E-4L,
    7.84039221720066627474E-4L,
    6.97281375836585777429E-5L
];

const real GammaSmallCoeffs[] = [
    0x1p+0,                  // 1
    0x1.2788cfc6fb618f52p-1,     // 0.57721566490153286082
    -0x1.4fcf4026afa2f7ecp-1, // -0.65587807152025406846
    -0x1.5815e8fa24d7e306p-5, // -0.042002635034033440541
    0x1.5512320aea2ad71ap-3,     // 0.16653861137208052067
    -0x1.59af0fb9d82e216p-5,     // -0.042197733607059154702
    -0x1.3b4b61d3bfdf244ap-7, // -0.0096220233604062716456
    0x1.d9358e9d9d69fd34p-8,     // 0.0072205994780369096722
    -0x1.38fc4bcbada775d6p-10 // -0.0011939450513815100956
];

const real GammaSmallNegCoeffs[] = [
    -0x1p+0,                     // -1
    0x1.2788cfc6fb618f54p-1,     // 0.57721566490153286086
    0x1.4fcf4026afa2bc4cp-1,     // 0.65587807152025365473
    -0x1.5815e8fa2468fec8p-5, // -0.042002635034021129105
    -0x1.5512320baedaf4b6p-3, // -0.16653861139444135193
    -0x1.59af0fa283baf07ep-5, // -0.042197733437311917216
    0x1.3b4a70de31e05942p-7,     // 0.0096219111550359767339
    0x1.d9398be3bad13136p-8,     // 0.0072208372618931703258
    0x1.291b73ee05bcbba2p-10     // 0.001133374167243894382
];

const real logGammaStirlingCoeffs[] = [
    0x1.5555555555553f98p-4,      // 0.083333333333333314473
    -0x1.6c16c16c07509b1p-9,      // -0.0027777777777503496034
    0x1.a01a012461cbf1e4p-11,  // 0.00079365077958550707556
    -0x1.3813089d3f9d164p-11,  // -0.00059523458517656885149
    0x1.b911a92555a277b8p-11,  // 0.00084127232973224980805
    -0x1.ed0a7b4206087b22p-10, // -0.0018808019381193769072
    0x1.402523859811b308p-8   // 0.0048850261424322707812
];

const real logGammaNumerator[] = [
    -0x1.0edd25913aaa40a2p+23, // -8875666.7836507038022
    -0x1.31c6ce2e58842d1ep+24, // -20039374.181038151756
    -0x1.f015814039477c3p+23,  // -16255680.62543700591
    -0x1.74ffe40c4b184b34p+22, // -6111225.0120052143001
    -0x1.0d9c6d08f9eab55p+20,  // -1104326.8146914642612
    -0x1.54c6b71935f1fc88p+16, // -87238.715228435114593
    -0x1.0e761b42932b2aaep+11  // -2163.6908276438128575
];

const real logGammaDenominator[] = [
    -0x1.4055572d75d08c56p+24, // -20993367.177578958762
    -0x1.deeb6013998e4d76p+24, // -31386464.076561826621
    -0x1.106f7cded5dcc79ep+24, // -17854332.870450781569
    -0x1.25e17184848c66d2p+22, // -4814940.3794118821866
    -0x1.301303b99a614a0ap+19, // -622744.11640662195015
    -0x1.09e76ab41ae965p+15,      // -34035.708405343046707
    -0x1.00f95ced9e5f54eep+9,  // -513.94814844353701437
    0x1p+0                    // 1
];

/*
 * Helper function: Gamma function computed by Stirling's formula.
 *
 * Stirling's formula for the gamma function is:
 *
 * $(GAMMA)(x) = sqrt(2 &pi;) x<sup>x-0.5</sup> exp(-x) (1 + 1/x P(1/x))
 *
 */
real gammaStirling(real x)
{
    // CEPHES code Copyright 1994 by Stephen L. Moshier

    real w = 1.0L/x;
    real y = exp(x);
    if ( x > 1024.0L ) {
        // For large x, use rational coefficients from the analytical expansion.
        w = poly(w, LargeStirlingCoeffs);
        // Avoid overflow in pow()
        real v = pow( x, 0.5L * x - 0.25L );
        y = v * (v / y);
    }
    else {
        w = 1.0L + w * poly( w, SmallStirlingCoeffs);
        y = pow( x, x - 0.5L ) / y;
    }
    y = SQRT2PI * y * w;
    return  y;
}

} // private

/****************
 * The sign of $(GAMMA)(x).
 *
 * Returns -1 if $(GAMMA)(x) < 0,  +1 if $(GAMMA)(x) > 0,
 * $(NAN) if sign is indeterminate.
 */
real sgnGamma(real x)
{
    /* Author: Don Clugston. */
    if (isNaN(x)) return x;
    if (x > 0) return 1.0;
    if (x < -1/real.epsilon) {
        // Large negatives lose all precision
        return real.nan;
    }
//  if (remquo(x, -1.0, n) == 0) {
    int n = cast(int)(x);
    if (x == n) {
        return x == 0 ?  copysign(1, x) : real.nan;
    }
    return n & 1 ? 1.0 : -1.0;
}

unittest {
    assert(sgnGamma(5.0) == 1.0);
    assert(isNaN(sgnGamma(-3.0)));
    assert(sgnGamma(-0.1) == -1.0);
    assert(sgnGamma(-55.1) == 1.0);
    assert(isNaN(sgnGamma(-real.infinity)));
    assert(isNaN(sgnGamma(real.nan)));
}

/*****************************************************
 *  The Gamma function, $(GAMMA)(x)
 *
 *  $(GAMMA)(x) is a generalisation of the factorial function
 *  to real and complex numbers.
 *  Like x!, $(GAMMA)(x+1) = x*$(GAMMA)(x).
 *
 *  Mathematically, if z.re > 0 then
 *   $(GAMMA)(z) = $(INTEGRATE 0, &infin;) $(POWER t, z-1)$(POWER e, -t) dt
 *
 *  $(TABLE_SV
 *    $(SVH  x,          $(GAMMA)(x) )
 *    $(SV  $(NAN),      $(NAN)      )
 *    $(SV  &plusmn;0.0, &plusmn;&infin;)
 *    $(SV integer > 0,  (x-1)!      )
 *    $(SV integer < 0,  $(NAN)      )
 *    $(SV +&infin;,     +&infin;    )
 *    $(SV -&infin;,     $(NAN)      )
 *  )
 */
real tgamma(real x)
{
/* Author: Don Clugston. Based on code from the CEPHES library.
 * CEPHES code Copyright 1994 by Stephen L. Moshier
 *
 * Arguments |x| <= 13 are reduced by recurrence and the function
 * approximated by a rational function of degree 7/8 in the
 * interval (2,3).  Large arguments are handled by Stirling's
 * formula. Large negative arguments are made positive using
 * a reflection formula.
 */

    real q, z;
    if (isNaN(x)) return x;
    if (x == -x.infinity) return real.nan;
    if ( fabs(x) > MAXGAMMA ) return real.infinity;
    if (x==0) return 1.0/x; // +- infinity depending on sign of x, create an exception.

    q = fabs(x);

    if ( q > 13.0L )    {
        // Large arguments are handled by Stirling's
        // formula. Large negative arguments are made positive using
        // the reflection formula.

        if ( x < 0.0L ) {
            int sgngam = 1; // sign of gamma.
            real p  = floor(q);
            if (p == q)
                  return real.nan; // poles for all integers <0.
            int intpart = cast(int)(p);
            if ( (intpart & 1) == 0 )
                sgngam = -1;
            z = q - p;
            if ( z > 0.5L ) {
                p += 1.0L;
                z = q - p;
            }
            z = q * sin( PI * z );
            z = fabs(z) * gammaStirling(q);
            if ( z <= PI/real.max ) return sgngam * real.infinity;
            return sgngam * PI/z;
        } else {
            return gammaStirling(x);
        }
    }

    // Arguments |x| <= 13 are reduced by recurrence and the function
    // approximated by a rational function of degree 7/8 in the
    // interval (2,3).

    z = 1.0L;
    while ( x >= 3.0L ) {
        x -= 1.0L;
        z *= x;
    }

    while ( x < -0.03125L ) {
        z /= x;
        x += 1.0L;
    }

    if ( x <= 0.03125L ) {
        if ( x == 0.0L )
            return real.nan;
        else {
            if ( x < 0.0L ) {
                x = -x;
                return z / (x * poly( x, GammaSmallNegCoeffs ));
            } else {
                return z / (x * poly( x, GammaSmallCoeffs ));
            }
        }
    }

    while ( x < 2.0L ) {
        z /= x;
        x += 1.0L;
    }
    if ( x == 2.0L ) return z;

    x -= 2.0L;
    return z * poly( x, GammaNumeratorCoeffs ) / poly( x, GammaDenominatorCoeffs );
}

unittest {
    // gamma(n) = factorial(n-1) if n is an integer.
    real fact = 1.0L;
    for (int i=1; fact<real.max; ++i) {
        // Require exact equality for small factorials
        if (i<14) assert(tgamma(i*1.0L) == fact);
        assert(feqrel(tgamma(i*1.0L), fact) > real.mant_dig-15);
        fact *= (i*1.0L);
    }
    assert(tgamma(0.0) == real.infinity);
    assert(tgamma(-0.0) == -real.infinity);
    assert(isNaN(tgamma(-1.0)));
    assert(isNaN(tgamma(-15.0)));
    assert(isNaN(tgamma(real.nan)));
    assert(tgamma(real.infinity) == real.infinity);
    assert(tgamma(real.max) == real.infinity);
    assert(isNaN(tgamma(-real.infinity)));
    assert(tgamma(real.min*real.epsilon) == real.infinity);

    // Test some high-precision values (50 decimal digits)
    const real SQRT_PI = 1.77245385090551602729816748334114518279754945612238L;

    assert(feqrel(tgamma(0.5L), SQRT_PI) == real.mant_dig);

    assert(feqrel(tgamma(1.0/3.L),  2.67893853470774763365569294097467764412868937795730L) >= real.mant_dig-2);
    assert(feqrel(tgamma(0.25L),
        3.62560990822190831193068515586767200299516768288006) >= real.mant_dig-1);
    assert(feqrel(tgamma(1.0/5.0L),
        4.59084371199880305320475827592915200343410999829340L) >= real.mant_dig-1);
}

/*****************************************************
 * Natural logarithm of gamma function.
 *
 * Returns the base e (2.718...) logarithm of the absolute
 * value of the gamma function of the argument.
 *
 * For reals, lgamma is equivalent to log(fabs(gamma(x))).
 *
 *  $(TABLE_SV
 *    $(SVH  x,             lgamma(x)   )
 *    $(SV  $(NAN),         $(NAN)      )
 *    $(SV integer <= 0,    +&infin;    )
 *    $(SV &plusmn;&infin;, +&infin;    )
 *  )
 */
real lgamma(real x)
{
    /* Author: Don Clugston. Based on code from the CEPHES library.
     * CEPHES code Copyright 1994 by Stephen L. Moshier
     *
     * For arguments greater than 33, the logarithm of the gamma
     * function is approximated by the logarithmic version of
     * Stirling's formula using a polynomial approximation of
     * degree 4. Arguments between -33 and +33 are reduced by
     * recurrence to the interval [2,3] of a rational approximation.
     * The cosecant reflection formula is employed for arguments
     * less than -33.
     */
    real q, w, z, f, nx;

    if (isNaN(x)) return x;
    if (fabs(x) == x.infinity) return x.infinity;

    if( x < -34.0L ) {
        q = -x;
        w = lgamma(q);
        real p = floor(q);
        if ( p == q ) return real.infinity;
        int intpart = cast(int)(p);
        real sgngam = 1;
        if ( (intpart & 1) == 0 )
            sgngam = -1;
        z = q - p;
        if ( z > 0.5L ) {
            p += 1.0L;
            z = p - q;
        }
        z = q * sin( PI * z );
        if ( z == 0.0L ) return sgngam * real.infinity;
    /*  z = LOGPI - logl( z ) - w; */
        z = log( PI/z ) - w;
        return z;
    }

    if( x < 13.0L ) {
        z = 1.0L;
        nx = floor( x +  0.5L );
        f = x - nx;
        while ( x >= 3.0L ) {
            nx -= 1.0L;
            x = nx + f;
            z *= x;
        }
        while ( x < 2.0L ) {
            if( fabs(x) <= 0.03125 ) {
                    if ( x == 0.0L ) return real.infinity;
                    if ( x < 0.0L ) {
                        x = -x;
                        q = z / (x * poly( x, GammaSmallNegCoeffs));
                    } else
                        q = z / (x * poly( x, GammaSmallCoeffs));
                    return log( fabs(q) );
            }
            z /= nx +  f;
            nx += 1.0L;
            x = nx + f;
        }
        z = fabs(z);
        if ( x == 2.0L )
            return log(z);
        x = (nx - 2.0L) + f;
        real p = x * poly( x, logGammaNumerator ) / poly( x, logGammaDenominator);
        return log(z) + p;
    }

    // const real MAXLGM = 1.04848146839019521116e+4928L;
    //  if( x > MAXLGM ) return sgngaml * real.infinity;

    const real LOGSQRT2PI  =  0.91893853320467274178L; // log( sqrt( 2*pi ) )

    q = ( x - 0.5L ) * log(x) - x + LOGSQRT2PI;
    if (x > 1.0e10L) return q;
    real p = 1.0L / (x*x);
    q += poly( p, logGammaStirlingCoeffs ) / x;
    return q ;
}

unittest {
    assert(isNaN(lgamma(real.nan)));
    assert(lgamma(real.infinity) == real.infinity);
    assert(lgamma(-1.0) == real.infinity);
    assert(lgamma(0.0) == real.infinity);
    assert(lgamma(-50.0) == real.infinity);
    assert(isIdentical(0.0L, lgamma(1.0L)));
    assert(isIdentical(0.0L, lgamma(2.0L)));
    assert(lgamma(real.min*real.epsilon) == real.infinity);
    assert(lgamma(-real.min*real.epsilon) == real.infinity);

    // x, correct loggamma(x), correct d/dx loggamma(x).
    static real[] testpoints = [
    8.0L,                    8.525146484375L      + 1.48766904143001655310E-5,   2.01564147795560999654E0L,
    8.99993896484375e-1L,    6.6375732421875e-2L  + 5.11505711292524166220E-6L, -7.54938684259372234258E-1,
    7.31597900390625e-1L,    2.2369384765625e-1   + 5.21506341809849792422E-6L, -1.13355566660398608343E0L,
    2.31639862060546875e-1L, 1.3686676025390625L  + 1.12609441752996145670E-5L, -4.56670961813812679012E0,
    1.73162841796875L,      -8.88214111328125e-2L + 3.36207740803753034508E-6L, 2.33339034686200586920E-1L,
    1.23162841796875L,      -9.3902587890625e-2L  + 1.28765089229009648104E-5L, -2.49677345775751390414E-1L,
    7.3786976294838206464e19L,   3.301798506038663053312e21L - 1.656137564136932662487046269677E5L,
                          4.57477139169563904215E1L,
    1.08420217248550443401E-19L, 4.36682586669921875e1L + 1.37082843669932230418E-5L,
                         -9.22337203685477580858E18L,
    1.0L, 0.0L, -5.77215664901532860607E-1L,
    2.0L, 0.0L, 4.22784335098467139393E-1L,
    -0.5L,  1.2655029296875L    + 9.19379714539648894580E-6L, 3.64899739785765205590E-2L,
    -1.5L,  8.6004638671875e-1L + 6.28657731014510932682E-7L, 7.03156640645243187226E-1L,
    -2.5L, -5.6243896484375E-2L + 1.79986700949327405470E-7,  1.10315664064524318723E0L,
    -3.5L,  -1.30902099609375L  + 1.43111007079536392848E-5L, 1.38887092635952890151E0L
    ];
   // TODO: test derivatives as well.
    for (int i=0; i<testpoints.length; i+=3) {
        assert( feqrel(lgamma(testpoints[i]), testpoints[i+1]) > real.mant_dig-5);
        if (testpoints[i]<MAXGAMMA) {
            assert( feqrel(log(fabs(tgamma(testpoints[i]))), testpoints[i+1]) > real.mant_dig-5);
        }
    }
    assert(lgamma(-50.2) == log(fabs(tgamma(-50.2))));
    assert(lgamma(-0.008) == log(fabs(tgamma(-0.008))));
    assert(feqrel(lgamma(-38.8),log(fabs(tgamma(-38.8)))) > real.mant_dig-4);
    assert(feqrel(lgamma(1500.0L),log(tgamma(1500.0L))) > real.mant_dig-2);
}
