/*
 *  Copyright (C) 2005-2006 Don Clugston
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

module std.math.special;

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
 *  <tr> <th> x               <th> $(GAMMA)(x)     <th>invalid?
 *  <tr> <td> $(NAN)          <td> $(NAN)          <td> yes
 *  <tr> <td> &plusmn;0.0     <td> &plusmn;&infin; <td> yes
 *  <tr> <td> integer > 0     <td> (x-1)!          <td> no
 *  <tr> <td> integer < 0     <td> $(NAN)          <td> yes
 *  <tr> <td> +&infin;        <td> +&infin;        <td> no
 *  <tr> <td> -&infin;        <td> $(NAN)          <td> yes
 *  )
 *
 *  References:
 *  $(LINK http://en.wikipedia.org/wiki/Gamma_function),
 *  $(LINK http://www.netlib.org/cephes/ldoubdoc.html#gamma)
 */
/* Documentation prepared by Don Clugston */
real gamma(real x)
{
    // NOTE: A native implementation of this function is
    //       available at http://www.dsource.org/mathextra
    return tango.stdc.math.tgammal(x);
}

/**
 * Natural logarithm of gamma function.
 *
 * Returns the base e (2.718...) logarithm of the absolute
 * value of the gamma function of the argument.
 *
 * For reals, lgamma is equivalent to log(fabs(gamma(x))).
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> lgamma(x)     <th>invalid?
 *  <tr> <td> $(NAN)          <td> $(NAN)        <td> yes
 *  <tr> <td> integer <= 0    <td> +&infin;      <td> yes
 *  <tr> <td> &plusmn;&infin; <td> +&infin;      <td> no
 *  )
 */
/* Documentation prepared by Don Clugston */
real loggamma(real x)
{
    // NOTE: A native implementation of this function is
    //       available at http://www.dsource.org/mathextra
    return tango.stdc.math.lgammal(x);
}