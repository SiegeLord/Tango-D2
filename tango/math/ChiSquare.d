/** Chi-square distribution and incomplete gamma function.
 *
 * Copyright: Copyright (C) 1984, 1995 Stephen L. Moshier
 *   Code taken from the Cephes Math Library Release 2.3:  January, 1995
 * License:   BSD style: $(LICENSE)
 * Authors:   Stephen L. Moshier, ported to D by Don Clugston
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

module tango.math.ChiSquare;
import tango.math.Core;
import tango.math.IEEE;
import tango.math.GammaFunction;
import tango.math.ErrorFunction;

/** $(POWER &chi;,2) cumulative distribution function and its complement.
 *
 * Returns the area under the left hand tail (from 0 to x)
 * of the Chi square probability density function with
 * v degrees of freedom. The complement returns the area under
 * the right hand tail (from x to &infin;).
 *
 *  chiSqrDistribution(x | v) = ($(INTEGRATE 0, x)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 *  chiSqrDistributionCompl(x | v) = ($(INTEGRATE x, &infin;)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 * Params:
 *  v  = degrees of freedom. Must be positive.
 *  x  = the $(POWER &chi;,2) variable. Must be positive.
 *
 */
real chiSqrDistribution(real v, real x)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
   return gammaIncomplete( 0.5*v, 0.5*x);
}

/** ditto */
real chiSqrDistributionCompl(real v, real x)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
    return gammaIncompleteCompl( 0.5L*v, 0.5L*x );
}

/**
 *  Inverse of complemented $(POWER &chi;, 2) distribution
 *
 * Finds the $(POWER &chi;, 2) argument x such that the integral
 * from x to &infin; of the $(POWER &chi;, 2) density is equal
 * to the given cumulative probability p.
 *
 * Params:
 * p = Cumulative probability. 0<= p <=1.
 * v = Degrees of freedom. Must be positive.
 *
 */
real chiSqrDistributionComplInv(real v, real p)
in {
  assert(p>=0 && p<=1.0L);
  assert(v>=1.0L);
}
body
{
   return  2.0 * gammaIncompleteComplInv( 0.5*v, p);
}

unittest {
  assert(feqrel(chiSqrDistributionCompl(3.5L, chiSqrDistributionComplInv(3.5L, 0.1L)), 0.1L)>=real.mant_dig-3);
  assert(chiSqrDistribution(19.02L, 0.4L) + chiSqrDistributionCompl(19.02L, 0.4L) ==1.0L);
}

/**
 * The Poisson distribution, its complement, and inverse
 *
 * k is the number of events. m is the mean.
 * The Poisson distribution is defined as the sum of the first k terms of
 * the Poisson density function.
 * The complement returns the sum of the terms k+1 to &infin;.
 *
 *   poissonDistribution = $(BIGSUM j=0, k) $(POWER e, -m) $(POWER m, j)/j!
 *
 * poissonDistributionCompl = $(BIGSUM j=k+1, &infin;) $(POWER e, -m) $(POWER m, j)/j!
 *
 * The terms are not summed directly; instead the incomplete
 * gamma integral is employed, according to the relation
 *
 * y = poissonDistribution( k, m ) = gammaIncompleteCompl( k+1, m ).
 *
 * The arguments must both be positive.
 */
real poissonDistribution(int k, real m )
in {
  assert(k>=0);
  assert(m>0);
}
body {
    return gammaIncompleteCompl( k+1.0, m );
}

/** ditto */
real poissonDistributionCompl(int k, real m )
in {
  assert(k>=0);
  assert(m>0);
}
body {
  return gammaIncomplete( k+1.0, m );
}

/** ditto */
real poissonDistributionInv( int k, real p )
in {
  assert(k>=0);
  assert(p>=0.0 && p<=1.0);
}
body {
    return gammaIncompleteComplInv(k+1, p);
}

unittest {
// = Excel's POISSON(k, m, TRUE)
    assert( fabs(poissonDistribution(5, 6.3)
                - 0.398771730072867L) < 0.000000000000005L);
    assert( feqrel(poissonDistributionInv(8, poissonDistribution(8, 2.7e3L)), 2.7e3L)>=real.mant_dig-2);
    assert( poissonDistribution(2, 8.4e-5) + poissonDistributionCompl(2, 8.4e-5) == 1.0L);
//  writefln("%.30g", poissonDistributionCompl(2, 0.1L));

//  writefln("%.30g", poissonDistribution(2, 2.7e-5L));

}


/***************************************
 *  Incomplete gamma integral and its complement
 *
 * These functions are defined by
 *
 *   gammaIncomplete = ( $(INTEGRATE 0, x) $(POWER e, -t) $(POWER t, a-1) dt )/ $(GAMMA)(a)
 *
 *  gammaIncompleteCompl(a,x)   =   1 - gammaIncomplete(a,x)
 * = ($(INTEGRATE x, &infin;) $(POWER e, -t) $(POWER t, a-1) dt )/ $(GAMMA)(a)
 *
 * In this implementation both arguments must be positive.
 * The integral is evaluated by either a power series or
 * continued fraction expansion, depending on the relative
 * values of a and x.
 */
real gammaIncomplete(real a, real x )
in {
   assert(x >= 0);
   assert(a > 0);
}
body {
    /* left tail of incomplete gamma function:
     *
     *          inf.      k
     *   a  -x   -       x
     *  x  e     >   ----------
     *           -     -
     *          k=0   | (a+k+1)
     *
     */
    if (x==0)
       return 0.0L;

    if ( (x > 1.0L) && (x > a ) )
        return 1.0L - gammaIncompleteCompl(a,x);

    real ax = a * log(x) - x - logGamma(a);
/+
    if( ax < MINLOGL ) return 0; // underflow
    //  { mtherr( "igaml", UNDERFLOW ); return( 0.0L ); }
+/
    ax = exp(ax);

    /* power series */
    real r = a;
    real c = 1.0L;
    real ans = 1.0L;

    do  {
        r += 1.0L;
        c *= x/r;
        ans += c;
    } while( c/ans > real.epsilon );

    return ans * ax/a;
}

/** ditto */
real gammaIncompleteCompl(real a, real x )
in {
   assert(x >= 0);
   assert(a > 0);
}
body {
    if (x==0)
       return 1.0L;
    if ( (x < 1.0L) || (x < a) )
        return 1.0L - gammaIncomplete(a,x);

   // DAC (Cephes bug fix): This is necessary to avoid
   // spurious nans, eg
   // log(x)-x = NaN when x = real.infinity
    const real MAXLOGL =  1.1356523406294143949492E4L;
   if (x > MAXLOGL) return 0; // underflow

    real ax = a * log(x) - x - logGamma(a);
//const real MINLOGL = -1.1355137111933024058873E4L;
//  if ( ax < MINLOGL ) return 0; // underflow;
    ax = exp(ax);


    /* continued fraction */
    real y = 1.0L - a;
    real z = x + y + 1.0L;
    real c = 0.0L;

    real pk, qk, t;

    real pkm2 = 1.0L;
    real qkm2 = x;
    real pkm1 = x + 1.0L;
    real qkm1 = z * x;
    real ans = pkm1/qkm1;

    do  {
        c += 1.0L;
        y += 1.0L;
        z += 2.0L;
        real yc = y * c;
        pk = pkm1 * z  -  pkm2 * yc;
        qk = qkm1 * z  -  qkm2 * yc;
        if( qk != 0.0L ) {
            real r = pk/qk;
            t = fabs( (ans - r)/r );
            ans = r;
        } else {
            t = 1.0L;
        }
    pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        const real BIG = 9.223372036854775808e18L;

        if ( fabs(pk) > BIG ) {
            pkm2 /= BIG;
            pkm1 /= BIG;
            qkm2 /= BIG;
            qkm1 /= BIG;
        }
    } while ( t > real.epsilon );

    return ans * ax;
}

/** Inverse of complemented incomplete gamma integral
 *
 * Given a and y, the function finds x such that
 *
 *  gammaIncompleteCompl( a, x ) = p.
 *
 * Starting with the approximate value x = a $(POWER t, 3), where
 * t = 1 - d - normalDistributionInv(p) sqrt(d),
 * and d = 1/9a,
 * the routine performs up to 10 Newton iterations to find the
 * root of incompleteGammaCompl(a,x) - p = 0.
 */
real gammaIncompleteComplInv(real a, real p)
in {
  assert(p>=0 && p<= 1);
  assert(a>0);
}
body {
    if (p==0) return real.infinity;

    real y0 = p;
    const real MAXLOGL =  1.1356523406294143949492E4L;
    real x0, x1, x, yl, yh, y, d, lgm, dithresh;
    int i, dir;

    /* bound the solution */
    x0 = real.max;
    yl = 0.0L;
    x1 = 0.0L;
    yh = 1.0L;
    dithresh = 4.0 * real.epsilon;

    /* approximation to inverse function */
    d = 1.0L/(9.0L*a);
    y = 1.0L - d - normalDistributionInv(y0) * sqrt(d);
    x = a * y * y * y;

    lgm = logGamma(a);

    for( i=0; i<10; i++ ) {
        if( x > x0 || x < x1 )
            goto ihalve;
        y = gammaIncompleteCompl(a,x);
        if ( y < yl || y > yh )
            goto ihalve;
        if ( y < y0 ) {
            x0 = x;
            yl = y;
        } else {
            x1 = x;
            yh = y;
        }
    /* compute the derivative of the function at this point */
        d = (a - 1.0L) * log(x0) - x0 - lgm;
        if ( d < -MAXLOGL )
            goto ihalve;
        d = -exp(d);
    /* compute the step to the next approximation of x */
        d = (y - y0)/d;
        x = x - d;
        if ( i < 3 ) continue;
        if ( fabs(d/x) < dithresh ) return x;
    }

    /* Resort to interval halving if Newton iteration did not converge. */
ihalve:
    d = 0.0625L;
    if ( x0 == real.max ) {
        if( x <= 0.0L )
            x = 1.0L;
        while( x0 == real.max ) {
            x = (1.0L + d) * x;
            y = gammaIncompleteCompl( a, x );
            if ( y < y0 ) {
                x0 = x;
                yl = y;
                break;
            }
            d = d + d;
        }
    }
    d = 0.5L;
    dir = 0;

    for( i=0; i<400; i++ ) {
        x = x1  +  d * (x0 - x1);
        y = gammaIncompleteCompl( a, x );
        lgm = (x0 - x1)/(x1 + x0);
        if ( fabs(lgm) < dithresh )
            break;
        lgm = (y - y0)/y0;
        if ( fabs(lgm) < dithresh )
            break;
        if ( x <= 0.0L )
            break;
        if ( y > y0 ) {
            x1 = x;
            yh = y;
            if ( dir < 0 ) {
                dir = 0;
                d = 0.5L;
            } else if ( dir > 1 )
                d = 0.5L * d + 0.5L;
            else
                d = (y0 - yl)/(yh - yl);
            dir += 1;
        } else {
            x0 = x;
            yl = y;
            if ( dir > 0 ) {
                dir = 0;
                d = 0.5L;
            } else if ( dir < -1 )
                d = 0.5L * d;
            else
                d = (y0 - yl)/(yh - yl);
            dir -= 1;
        }
    }
    /+
    if( x == 0.0L )
        mtherr( "igamil", UNDERFLOW );
    +/
    return x;
}

unittest {
//Values from Excel's GammaInv(1-p, x, 1)
assert(fabs(gammaIncompleteComplInv(1, 0.5) - 0.693147188044814) < 0.00000005);
assert(fabs(gammaIncompleteComplInv(12, 0.99) - 5.42818075054289) < 0.00000005);
assert(fabs(gammaIncompleteComplInv(100, 0.8) - 91.5013985848288L) < 0.000005);

assert(gammaIncomplete(1, 0)==0);
assert(gammaIncompleteCompl(1, 0)==1);
assert(gammaIncomplete(4545, real.infinity)==1);

// Values from Excel's (1-GammaDist(x, alpha, 1, TRUE))

assert(fabs(1.0L-gammaIncompleteCompl(0.5, 2) - 0.954499729507309L) < 0.00000005);
assert(fabs(gammaIncomplete(0.5, 2) - 0.954499729507309L) < 0.00000005);
// Fixed Cephes bug:
assert(gammaIncompleteCompl(384, real.infinity)==0);
assert(gammaIncompleteComplInv(3, 0)==real.infinity);

//writefln("%.20g",gammaIncompleteCompl(100, 0));
//assert(gammaIncompleteComplInv(8, 0));

// BUG: infinite loop if p == 0!
//writefln(gammaIncompleteComplInv(8, 0));

//writefln(gammaIncompleteComplInv(8, 1e-50));
//writefln(gammaIncompleteComplInv(12, 0.99));

}