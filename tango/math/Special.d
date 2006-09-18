/**
 * Mathematical Special Functions
 *
 * Publicly imports all of the Tango special functions.
 *
 * Copyright: Copyright (C) 2005-2006 Don Clugston
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 */

/**
 * Macros:
 *  NAN = $(RED NAN)
 *  SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *  GAMMA =  &#915;
 *  INTEGRAL = &#8747;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  BIGSUM = $(BIG &Sigma; <sup>$2</sup><sub>$(SMALL $1)</sub>)
 *  CHOOSE = $(BIG &#40;) <sup>$(SMALL $1)</sup><sub>$(SMALL $2)</sub> $(BIG &#41;)
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 */

module tango.math.Special;
static import tango.math.GammaFunction;
public import tango.math.Bessel;

private import tango.stdc.math;


/**
 * Returns the error function of x.
 */
real erf(real x)
{
    return tango.stdc.math.erfl(x);
}

/**
 * Returns the complementary error function of x, which is 1 - erf(x).
 */
real erfc(real x)
{
    return tango.stdc.math.erfcl(x);
}

/**
 *  The Gamma function, $(GAMMA)(x)
 *
 *  $(GAMMA)(x) is a generalisation of the factorial function
 *  to real and complex numbers.
 *  Like x!, $(GAMMA)(x+1) = x*$(GAMMA)(x).
 *
 *  Mathematically, if z.re > 0 then
 *   $(GAMMA)(z) =<big>$(INTEGRAL)<sub><small>0</small></sub><sup>&infin;</sup></big>t<sup>z-1</sup>e<sup>-t</sup>dt
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> $(GAMMA)(x)
 *  <tr> <td> $(NAN)          <td> $(NAN)
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;&infin;
 *  <tr> <td> integer > 0     <td> (x-1)!
 *  <tr> <td> integer < 0     <td> $(NAN)
 *  <tr> <td> +&infin;        <td> +&infin;
 *  <tr> <td> -&infin;        <td> $(NAN)
 *  )
 *
 *  References:
 *  $(LINK http://en.wikipedia.org/wiki/Gamma_function),
 *  $(LINK http://www.netlib.org/cephes/ldoubdoc.html#gamma)
 */
real gamma(real x)
{
    return tango.math.GammaFunction.tgamma(x);
}

/**
 * Natural logarithm of gamma function.
 *
 * Returns the base e (2.718...) logarithm of the absolute
 * value of the gamma function of the argument.
 *
 * For reals, logGamma is equivalent to log(fabs(gamma(x))).
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> logGamma(x)
 *  <tr> <td> $(NAN)          <td> $(NAN)
 *  <tr> <td> integer <= 0    <td> +&infin;
 *  <tr> <td> &plusmn;&infin; <td> +&infin;
 *  )
 */
real logGamma(real x)
{
    return tango.math.GammaFunction.lgamma(x);
}