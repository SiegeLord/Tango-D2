/** Beta function, incomplete beta integral, and related statistical functions
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
module tango.math.BetaFunction;

import tango.math.Core;
import tango.math.IEEE;
import tango.math.ErrorFunction;
import tango.math.GammaFunction;

private {
const real MAXLOG = 0x1.62e42fefa39ef358p+13L;  // log(real.max)
const real MINLOG = -0x1.6436716d5406e6d8p+13L; // log(real.min*real.epsilon) = log(smallest denormal)
const real big = 9.223372036854775808e18L;
const real biginv = 1.084202172485504434007e-19L;
}

/** Beta function
 *
 * The beta function is defined as
 *
 * beta(x, y) = (&Gamma;(x) &Gamma;(y))/&Gamma;(x + y)
 */
real beta(real x, real y)
{
    if ((x+y)> MAXGAMMA) {
        return exp(logGamma(x) + logGamma(y) - logGamma(x+y));
    } else return gamma(x)*gamma(y)/gamma(x+y);
}

unittest {
    assert(isIdentical(beta(NaN("abc"), 4), NaN("abc")));
    assert(isIdentical(beta(2, NaN("abc")), NaN("abc")));
}

/** Incomplete beta integral
 *
 * Returns incomplete beta integral of the arguments, evaluated
 * from zero to x. The regularized incomplete beta function is defined as
 *
 * betaIncomplete(a, b, x) = &Gamma;(a+b)/(&Gamma;(a) &Gamma;(b)) *
 * $(INTEGRATE 0, x) $(POWER t, a-1)$(POWER (1-t),b-1) dt
 *
 * and is the same as the the cumulative distribution function:

 * The domain of definition is 0 <= x <= 1.  In this
 * implementation a and b are restricted to positive values.
 * The integral from x to 1 may be obtained by the symmetry
 * relation
 *
 *    betaIncompleteCompl(a, b, x )  =  betaIncomplete( b, a, 1-x )
 *
 * The integral is evaluated by a continued fraction expansion
 * or, when b*x is small, by a power series.
 */
real betaIncomplete(real aa, real bb, real xx )
{
    if (!(aa>0 && bb>0)) {
         if (isNaN(aa)) return aa;
         if (isNaN(bb)) return bb;
         return NaN("beta"); // domain error
    }
    if (!(xx>0 && xx<1.0)) {
        if (isNaN(xx)) return xx;
        if ( xx == 0.0L ) return 0.0;
        if ( xx == 1.0L )  return 1.0;
        return NaN("beta"); // domain error
    }
    if ( (bb * xx) <= 1.0L && xx <= 0.95L)   {
        return betaDistPowerSeries(aa, bb, xx);
    }
    real x;
    real xc; // = 1 - x

    real a, b;
    int flag = 0;

    /* Reverse a and b if x is greater than the mean. */
    if( xx > (aa/(aa+bb)) ) {
        // here x > aa/(aa+bb) and (bb*x>1 or x>0.95)
        flag = 1;
        a = bb;
        b = aa;
        xc = xx;
        x = 1.0L - xx;
    } else {
        a = aa;
        b = bb;
        xc = 1.0L - xx;
        x = xx;
    }

    if( flag == 1 && (b * x) <= 1.0L && x <= 0.95L) {
        // here xx > aa/(aa+bb) and  ((bb*xx>1) or xx>0.95) and (aa*(1-xx)<=1) and xx > 0.05
        return 1.0 - betaDistPowerSeries(a, b, x); // note loss of precision
    }

    real w;
    // Choose expansion for optimal convergence
    // One is for x * (a+b+2) < (a+1),
    // the other is for x * (a+b+2) > (a+1).
    real y = x * (a+b-2.0L) - (a-1.0L);
    if( y < 0.0L ) {
        w = betaDistExpansion1( a, b, x );
    } else {
        w = betaDistExpansion2( a, b, x ) / xc;
    }

    /* Multiply w by the factor
         a      b
        x  (1-x)   Gamma(a+b) / ( a Gamma(a) Gamma(b) ) .   */

    y = a * log(x);
    real t = b * log(xc);
    if ( (a+b) < MAXGAMMA && fabs(y) < MAXLOG && fabs(t) < MAXLOG ) {
        t = pow(xc,b);
        t *= pow(x,a);
        t /= a;
        t *= w;
        t *= gamma(a+b) / (gamma(a) * gamma(b));
    } else {
        /* Resort to logarithms.  */
        y += t + logGamma(a+b) - logGamma(a) - logGamma(b);
        y += log(w/a);

        // DAC: There was a bug in Cephes at this point.
        // Problems occur for y > MAXLOG, not y < MINLOG.
        t = exp(y);
/+      // Cephes bug
        if( y < MINLOG ) {
            t = 0.0L;
        } else {
            t = exp(y);
        }
+/
    }
    if( flag == 1 ) {
/+   // CEPHES includes this code, but I think it is erroneous.
        if( t <= real.epsilon ) {
            t = 1.0L - real.epsilon;
        } else
+/
        t = 1.0L - t;
    }
    return t;
}

/** Inverse of incomplete beta integral
 *
 * Given y, the function finds x such that
 *
 *  betaIncomplete(a, b, x) == y
 *
 *  Newton iterations or interval halving is used.
 */
real betaIncompleteInv(real aa, real bb, real yy0 )
{
    real a, b, y0, d, y, x, x0, x1, lgm, yp, di, dithresh, yl, yh, xt;
    int i, rflg, dir, nflg;

    if (isNaN(yy0)) return yy0;
    if (isNaN(aa)) return aa;
    if (isNaN(bb)) return bb;
    if( yy0 <= 0.0L )
        return 0.0L;
    if( yy0 >= 1.0L )
        return 1.0L;
    x0 = 0.0L;
    yl = 0.0L;
    x1 = 1.0L;
    yh = 1.0L;
    if( aa <= 1.0L || bb <= 1.0L ) {
        dithresh = 1.0e-7L;
        rflg = 0;
        a = aa;
        b = bb;
        y0 = yy0;
        x = a/(a+b);
        y = betaIncomplete( a, b, x );
        nflg = 0;
        goto ihalve;
    } else {
        nflg = 0;
        dithresh = 1.0e-4L;
    }

    /* approximation to inverse function */

    yp = -normalDistributionInv( yy0 );

    if( yy0 > 0.5L ) {
        rflg = 1;
        a = bb;
        b = aa;
        y0 = 1.0L - yy0;
        yp = -yp;
    } else {
        rflg = 0;
        a = aa;
        b = bb;
        y0 = yy0;
    }

    lgm = (yp * yp - 3.0L)/6.0L;
    x = 2.0L/( 1.0L/(2.0L * a-1.0L)  +  1.0L/(2.0L * b - 1.0L) );
    d = yp * sqrt( x + lgm ) / x
        - ( 1.0L/(2.0L * b - 1.0L) - 1.0L/(2.0L * a - 1.0L) )
        * (lgm + (5.0L/6.0L) - 2.0L/(3.0L * x));
    d = 2.0L * d;
    if( d < MINLOG ) {
        x = 1.0L;
        goto under;
    }
    x = a/( a + b * exp(d) );
    y = betaIncomplete( a, b, x );
    yp = (y - y0)/y0;
    if( fabs(yp) < 0.2 )
        goto newt;

    /* Resort to interval halving if not close enough. */
ihalve:

    dir = 0;
    di = 0.5L;
    for( i=0; i<400; i++ ) {
        if( i != 0 ) {
            x = x0  +  di * (x1 - x0);
            if( x == 1.0L ) {
                x = 1.0L - real.epsilon;
            }
            if( x == 0.0L ) {
                di = 0.5;
                x = x0  +  di * (x1 - x0);
                if( x == 0.0 )
                    goto under;
            }
            y = betaIncomplete( a, b, x );
            yp = (x1 - x0)/(x1 + x0);
            if( fabs(yp) < dithresh )
                goto newt;
            yp = (y-y0)/y0;
            if( fabs(yp) < dithresh )
                goto newt;
        }
        if( y < y0 ) {
            x0 = x;
            yl = y;
            if( dir < 0 ) {
                dir = 0;
                di = 0.5L;
            } else if( dir > 3 )
                di = 1.0L - (1.0L - di) * (1.0L - di);
            else if( dir > 1 )
                di = 0.5L * di + 0.5L;
            else
                di = (y0 - y)/(yh - yl);
            dir += 1;
            if( x0 > 0.95L ) {
                if( rflg == 1 ) {
                    rflg = 0;
                    a = aa;
                    b = bb;
                    y0 = yy0;
                } else {
                    rflg = 1;
                    a = bb;
                    b = aa;
                    y0 = 1.0 - yy0;
                }
                x = 1.0L - x;
                y = betaIncomplete( a, b, x );
                x0 = 0.0;
                yl = 0.0;
                x1 = 1.0;
                yh = 1.0;
                goto ihalve;
            }
        } else {
            x1 = x;
            if( rflg == 1 && x1 < real.epsilon ) {
                x = 0.0L;
                goto done;
            }
            yh = y;
            if( dir > 0 ) {
                dir = 0;
                di = 0.5L;
            }
            else if( dir < -3 )
                di = di * di;
            else if( dir < -1 )
                di = 0.5L * di;
            else
                di = (y - y0)/(yh - yl);
            dir -= 1;
            }
        }
    // loss of precision has occurred

    //mtherr( "incbil", PLOSS );
    if( x0 >= 1.0L ) {
        x = 1.0L - real.epsilon;
        goto done;
    }
    if( x <= 0.0L ) {
under:
        // underflow has occurred
        //mtherr( "incbil", UNDERFLOW );
        x = 0.0L;
        goto done;
    }

newt:

    if ( nflg ) {
        goto done;
    }
    nflg = 1;
    lgm = logGamma(a+b) - logGamma(a) - logGamma(b);

    for( i=0; i<15; i++ ) {
        /* Compute the function at this point. */
        if ( i != 0 )
            y = betaIncomplete(a,b,x);
        if ( y < yl ) {
            x = x0;
            y = yl;
        } else if( y > yh ) {
            x = x1;
            y = yh;
        } else if( y < y0 ) {
            x0 = x;
            yl = y;
        } else {
            x1 = x;
            yh = y;
        }
        if( x == 1.0L || x == 0.0L )
            break;
        /* Compute the derivative of the function at this point. */
        d = (a - 1.0L) * log(x) + (b - 1.0L) * log(1.0L - x) + lgm;
        if ( d < MINLOG ) {
            goto done;
        }
        if ( d > MAXLOG ) {
            break;
        }
        d = exp(d);
        /* Compute the step to the next approximation of x. */
        d = (y - y0)/d;
        xt = x - d;
        if ( xt <= x0 ) {
            y = (x - x0) / (x1 - x0);
            xt = x0 + 0.5L * y * (x - x0);
            if( xt <= 0.0L )
                break;
        }
        if ( xt >= x1 ) {
            y = (x1 - x) / (x1 - x0);
            xt = x1 - 0.5L * y * (x1 - x);
            if ( xt >= 1.0L )
                break;
        }
        x = xt;
        if ( fabs(d/x) < (128.0L * real.epsilon) )
            goto done;
        }
    /* Did not converge.  */
    dithresh = 256.0L * real.epsilon;
    goto ihalve;

done:
    if ( rflg ) {
        if( x <= real.epsilon )
            x = 1.0L - real.epsilon;
        else
            x = 1.0L - x;
    }
    return x;
}

unittest { // also tested by the normal distribution
  // check NaN propagation
  assert(isIdentical(betaIncomplete(NaN("xyz"),2,3), NaN("xyz")));
  assert(isIdentical(betaIncomplete(7,NaN("xyz"),3), NaN("xyz")));
  assert(isIdentical(betaIncomplete(7,15,NaN("xyz")), NaN("xyz")));
  assert(isIdentical(betaIncompleteInv(NaN("xyz"),1,17), NaN("xyz")));
  assert(isIdentical(betaIncompleteInv(2,NaN("xyz"),8), NaN("xyz")));
  assert(isIdentical(betaIncompleteInv(2,3, NaN("xyz")), NaN("xyz")));

  assert(isNaN(betaIncomplete(-1, 2, 3)));

  assert(betaIncomplete(1, 2, 0)==0);
  assert(betaIncomplete(1, 2, 1)==1);
  assert(isNaN(betaIncomplete(1, 2, 3)));
  assert(betaIncompleteInv(1, 1, 0)==0);
  assert(betaIncompleteInv(1, 1, 1)==1);

  // Test some values against Microsoft Excel 2003.

  assert(fabs(betaIncomplete(8, 10, 0.2) - 0.010_934_315_236_957_2L) < 0.000_000_000_5);
  assert(fabs(betaIncomplete(2, 2.5, 0.9) - 0.989_722_597_604_107L) < 0.000_000_000_000_5);
  assert(fabs(betaIncomplete(1000, 800, 0.5) - 1.17914088832798E-06L) < 0.000_000_05e-6);

  assert(fabs(betaIncomplete(0.0001, 10000, 0.0001) - 0.999978059369989L) < 0.000_000_000_05);

  assert(fabs(betaIncompleteInv(5, 10, 0.2) - 0.229121208190918L) < 0.000_000_5L);
  assert(fabs(betaIncompleteInv(4, 7, 0.8) - 0.483657360076904L) < 0.000_000_5L);

    // Coverage tests. I don't have correct values for these tests, but
    // these values cover most of the code, so they are useful for
    // regression testing.
    // Extensive testing failed to increase the coverage. It seems likely that about
    // half the code in this function is unnecessary; there is potential for
    // significant improvement over the original CEPHES code.

// Excel 2003 gives clearly erroneous results (betadist>1) when a and x are tiny and b is huge.
// The correct results are for these next tests are unknown.

//    real testpoint1 = betaIncomplete(1e-10, 5e20, 8e-21);
//    assert(testpoint1 == 0x1.ffff_ffff_c906_404cp-1L);



    assert(betaIncomplete(0.01, 327726.7, 0.545113) == 1.0);
    assert(betaIncompleteInv(0.01, 8e-48, 5.45464e-20)==1-real.epsilon);
    assert(betaIncompleteInv(0.01, 8e-48, 9e-26)==1-real.epsilon);

    assert(betaIncomplete(0.01, 498.437, 0.0121433) == 0x1.ffff_8f72_19197402p-1);
    assert(1- betaIncomplete(0.01, 328222, 4.0375e-5) == 0x1.5f62926b4p-30);
    assert(betaIncompleteInv(0x1.b3d151fbba0eb18p+1, 1.2265e-19, 2.44859e-18)==0x1.c0110c8531d0952cp-1);
    assert(betaIncompleteInv(0x1.ff1275ae5b939bcap-41, 4.6713e18, 0.0813601)==0x1.f97749d90c7adba8p-63);
    real a1;
    a1 = 3.40483;
    assert(betaIncompleteInv(a1, 4.0640301659679627772e19L, 0.545113)== 0x1.ba8c08108aaf5d14p-109);
    real b1;
    b1= 2.82847e-25;
    assert(betaIncompleteInv(0.01, b1, 9e-26) == 0x1.549696104490aa9p-830);

    // --- Problematic cases ---
    // This is a situation where the series expansion fails to converge
    assert( isNaN(betaIncompleteInv(0.12167, 4.0640301659679627772e19L, 0.0813601)));
    // This next result is almost certainly erroneous.
    assert(betaIncomplete(1.16251e20, 2.18e39, 5.45e-20)==-real.infinity);
}

private {
// Implementation functions

// Continued fraction expansion #1 for incomplete beta integral
// Use when x < (a+1)/(a+b+2)
real betaDistExpansion1(real a, real b, real x )
{
    real xk, pk, pkm1, pkm2, qk, qkm1, qkm2;
    real k1, k2, k3, k4, k5, k6, k7, k8;
    real r, t, ans;
    int n;

    k1 = a;
    k2 = a + b;
    k3 = a;
    k4 = a + 1.0L;
    k5 = 1.0L;
    k6 = b - 1.0L;
    k7 = k4;
    k8 = a + 2.0L;

    pkm2 = 0.0L;
    qkm2 = 1.0L;
    pkm1 = 1.0L;
    qkm1 = 1.0L;
    ans = 1.0L;
    r = 1.0L;
    n = 0;
    const real thresh = 3.0L * real.epsilon;
    do  {
        xk = -( x * k1 * k2 )/( k3 * k4 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        xk = ( x * k5 * k6 )/( k7 * k8 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        if( qk != 0.0L )
            r = pk/qk;
        if( r != 0.0L ) {
            t = fabs( (ans - r)/r );
            ans = r;
        } else {
           t = 1.0L;
        }

        if( t < thresh )
            return ans;

        k1 += 1.0L;
        k2 += 1.0L;
        k3 += 2.0L;
        k4 += 2.0L;
        k5 += 1.0L;
        k6 -= 1.0L;
        k7 += 2.0L;
        k8 += 2.0L;

        if( (fabs(qk) + fabs(pk)) > big ) {
            pkm2 *= biginv;
            pkm1 *= biginv;
            qkm2 *= biginv;
            qkm1 *= biginv;
            }
        if( (fabs(qk) < biginv) || (fabs(pk) < biginv) ) {
            pkm2 *= big;
            pkm1 *= big;
            qkm2 *= big;
            qkm1 *= big;
            }
        }
    while( ++n < 400 );
// loss of precision has occurred
// mtherr( "incbetl", PLOSS );
    return ans;
}

// Continued fraction expansion #2 for incomplete beta integral
// Use when x > (a+1)/(a+b+2)
real betaDistExpansion2(real a, real b, real x )
{
    real  xk, pk, pkm1, pkm2, qk, qkm1, qkm2;
    real k1, k2, k3, k4, k5, k6, k7, k8;
    real r, t, ans, z;

    k1 = a;
    k2 = b - 1.0L;
    k3 = a;
    k4 = a + 1.0L;
    k5 = 1.0L;
    k6 = a + b;
    k7 = a + 1.0L;
    k8 = a + 2.0L;

    pkm2 = 0.0L;
    qkm2 = 1.0L;
    pkm1 = 1.0L;
    qkm1 = 1.0L;
    z = x / (1.0L-x);
    ans = 1.0L;
    r = 1.0L;
    int n = 0;
    const real thresh = 3.0L * real.epsilon;
    do {

        xk = -( z * k1 * k2 )/( k3 * k4 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        xk = ( z * k5 * k6 )/( k7 * k8 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        if( qk != 0.0L )
            r = pk/qk;
        if( r != 0.0L ) {
            t = fabs( (ans - r)/r );
            ans = r;
        } else
            t = 1.0L;

        if( t < thresh )
            return ans;
        k1 += 1.0L;
        k2 -= 1.0L;
        k3 += 2.0L;
        k4 += 2.0L;
        k5 += 1.0L;
        k6 += 1.0L;
        k7 += 2.0L;
        k8 += 2.0L;

        if( (fabs(qk) + fabs(pk)) > big ) {
            pkm2 *= biginv;
            pkm1 *= biginv;
            qkm2 *= biginv;
            qkm1 *= biginv;
        }
        if( (fabs(qk) < biginv) || (fabs(pk) < biginv) ) {
            pkm2 *= big;
            pkm1 *= big;
            qkm2 *= big;
            qkm1 *= big;
        }
    } while( ++n < 400 );
// loss of precision has occurred
//mtherr( "incbetl", PLOSS );
    return ans;
}

/* Power series for incomplete gamma integral.
   Use when b*x is small.  */
real betaDistPowerSeries(real a, real b, real x )
{
    real ai = 1.0L / a;
    real u = (1.0L - b) * x;
    real v = u / (a + 1.0L);
    real t1 = v;
    real t = u;
    real n = 2.0L;
    real s = 0.0L;
    real z = real.epsilon * ai;
    while( fabs(v) > z ) {
        u = (n - b) * x / n;
        t *= u;
        v = t / (a + n);
        s += v;
        n += 1.0L;
    }
    s += t1;
    s += ai;

    u = a * log(x);
    if ( (a+b) < MAXGAMMA && fabs(u) < MAXLOG ) {
        t = gamma(a+b)/(gamma(a)*gamma(b));
        s = s * t * pow(x,a);
    } else {
        t = logGamma(a+b) - logGamma(a) - logGamma(b) + u + log(s);

        if( t < MINLOG ) {
            s = 0.0L;
        } else
            s = exp(t);
    }
    return s;
}

}

/** Student's t cumulative distribution function
 *
 * Computes the integral from minus infinity to t of the Student
 * t distribution with integer nu > 0 degrees of freedom:
 *
 *   $(GAMMA)( (nu+1)/2) / ( sqrt(nu &pi;) $(GAMMA)(nu/2) ) *
 * $(INTEGRATE -&infin;, t) $(POWER (1+$(POWER x, 2)/nu), -(nu+1)/2) dx
 *
 * It is related to the incomplete beta integral:
 *        1 - studentsDistribution(nu,t) = 0.5 * betaDistribution( nu/2, 1/2, z )
 * where
 *        z = nu/(nu + t<sup>2</sup>).
 *
 * For t < -1.6, this is the method of computation.  For higher t,
 * a direct method is derived from integration by parts.
 * Since the function is symmetric about t=0, the area under the
 * right tail of the density is found by calling the function
 * with -t instead of t.
 */
real studentsDistribution(int nu, real t)
{
  // Author: Don Clugston. Public domain.
  /* Based on code from Cephes Math Library Release 2.3:  January, 1995
     Copyright 1984, 1995 by Stephen L. Moshier
 */


    if ( nu <= 0 ) return real.nan; // domain error -- or should it return 0?
    if ( t == 0.0 )  return 0.5;

    real rk, z, p;

    if ( t < -1.6 ) {
        rk = nu;
        z = rk / (rk + t * t);
        return 0.5L * betaIncomplete( 0.5L*rk, 0.5L, z );
    }

    /*  compute integral from -t to + t */

    rk = nu;    /* degrees of freedom */

    real x;
    if (t < 0) x = -t; else x = t;
    z = 1.0L + ( x * x )/rk;

    real f, tz;
    int j;

    if ( nu & 1)    {
        /*  computation for odd nu  */
        real xsqk = x/sqrt(rk);
        p = atan( xsqk );
        if ( nu > 1 )   {
            f = 1.0L;
            tz = 1.0L;
            j = 3;
            while(  (j<=(nu-2)) && ( (tz/f) > real.epsilon )  ) {
                tz *= (j-1)/( z * j );
                f += tz;
                j += 2;
            }
            p += f * xsqk/z;
            }
        p *= 2.0L/PI;
    } else {
        /*  computation for even nu */
        f = 1.0L;
        tz = 1.0L;
        j = 2;

        while ( ( j <= (nu-2) ) && ( (tz/f) > real.epsilon )  ) {
            tz *= (j - 1)/( z * j );
            f += tz;
            j += 2;
        }
        p = f * x/sqrt(z*rk);
    }
    if ( t < 0.0L )
        p = -p; /* note destruction of relative accuracy */

    p = 0.5L + 0.5L * p;
    return p;
}

/** Inverse of Student's t distribution
 *
 * Given probability p and degrees of freedom nu,
 * finds the argument t such that the one-sided
 * studentsDistribution(nu,t) is equal to p.
 * Used to test whether two distributions have the same
 * standard deviation.
 *
 * Params:
 * nu = degrees of freedom. Must be >1
 * p  = probability. 0 < p < 1
 */
real studentsDistributionInv(int nu, real p )
// Author: Don Clugston. Public domain.
in {
   assert(nu>0);
   assert(p>=0.0L && p<=1.0L);
}
body
{
    if (p==0) return -real.infinity;
    if (p==1) return real.infinity;

    real rk, z;
    rk =  nu;

    if ( p > 0.25L && p < 0.75L ) {
        if ( p == 0.5L ) return 0;
        z = 1.0L - 2.0L * p;
        z = betaIncompleteInv( 0.5L, 0.5L*rk, fabs(z) );
        real t = sqrt( rk*z/(1.0L-z) );
        if( p < 0.5L )
            t = -t;
        return t;
    }
    int rflg = -1; // sign of the result
    if (p >= 0.5L) {
        p = 1.0L - p;
        rflg = 1;
    }
    z = betaIncompleteInv( 0.5L*rk, 0.5L, 2.0L*p );

    if (z<0) return rflg * real.infinity;
    return rflg * sqrt( rk/z - rk );
}

unittest {

// There are simple forms for nu = 1 and nu = 2.

// if (nu == 1), tDistribution(x) = 0.5 + atan(x)/PI
//              so tDistributionInv(p) = tan( PI * (p-0.5) );
// nu==2: tDistribution(x) = 0.5 * (1 + x/ sqrt(2+x*x) )

assert( studentsDistribution(1, -0.4)== 0.5 + atan(-0.4)/PI);
assert(studentsDistribution(2, 0.9) == 0.5L * (1 + 0.9L/sqrt(2.0L + 0.9*0.9)) );
assert(studentsDistribution(2, -5.4) == 0.5L * (1 - 5.4L/sqrt(2.0L + 5.4*5.4)) );

// return true if a==b to given number of places.
bool isfeqabs(real a, real b, real diff)
{
  return fabs(a-b) < diff;
}

// Check a few spot values with statsoft.com (Mathworld values are wrong!!)
// According to statsoft.com, studentsDistributionInv(10, 0.995)= 3.16927.

// The remaining values listed here are from Excel, and are unlikely to be accurate
// in the last decimal places. However, they are helpful as a sanity check.

//  Microsoft Excel 2003 gives TINV(2*(1-0.995), 10) == 3.16927267160917
assert(isfeqabs(studentsDistributionInv(10, 0.995), 3.169_272_67L, 0.000_000_005L));


assert(isfeqabs(studentsDistributionInv(8, 0.6), 0.261_921_096_769_043L,0.000_000_000_05L));
// -TINV(2*0.4, 18) ==  -0.257123042655869

assert(isfeqabs(studentsDistributionInv(18, 0.4), -0.257_123_042_655_869L, 0.000_000_000_05L));
assert( feqrel(studentsDistribution(18, studentsDistributionInv(18, 0.4L)),0.4L)
 > real.mant_dig-2 );
assert( feqrel(studentsDistribution(11, studentsDistributionInv(11, 0.9L)),0.9L)
  > real.mant_dig-2);

}

/** The Fisher distribution, its complement, and inverse.
 *
 * The F density function (also known as Snedcor's density or the
 * variance ratio density) is the density
 * of x = (u1/df1)/(u2/df2), where u1 and u2 are random
 * variables having $(POWER &chi;,2) distributions with df1
 * and df2 degrees of freedom, respectively.
 *
 * fDistribution returns the area from zero to x under the F density
 * function.   The complementary function,
 * fDistributionCompl, returns the area from x to &infin; under the F density function.
 *
 * The inverse of the complemented Fisher distribution,
 * fDistributionComplInv, finds the argument x such that the integral
 * from x to infinity of the F density is equal to the given probability y.

 * Params:
 *  df1 = Degrees of freedom of the first variable. Must be >= 1
 *  df2 = Degrees of freedom of the second variable. Must be >= 1
 *  x  = Must be >= 0
 */
real fDistribution(int df1, int df2, real x)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = a * x;
    w = w/(b + w);
    return betaIncomplete(0.5L*a, 0.5L*b, w);
}

/** ditto */
real fDistributionCompl(int df1, int df2, real x)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = b / (b + a * x);
    return betaIncomplete( 0.5L*b, 0.5L*a, w );
}

/*
 * Inverse of complemented Fisher distribution
 *
 * Finds the F density argument x such that the integral
 * from x to infinity of the F density is equal to the
 * given probability p.
 *
 * This is accomplished using the inverse beta integral
 * function and the relations
 *
 *      z = betaIncompleteInv( df2/2, df1/2, p ),
 *      x = df2 (1-z) / (df1 z).
 *
 * Note that the following relations hold for the inverse of
 * the uncomplemented F distribution:
 *
 *      z = betaIncompleteInv( df1/2, df2/2, p ),
 *      x = df2 z / (df1 (1-z)).
*/

/** ditto */
real fDistributionComplInv(int df1, int df2, real p )
in {
 assert(df1>=1 && df2>=1);
 assert(p>=0 && p<=1.0);
}
body{
    real a = df1;
    real b = df2;
    /* Compute probability for x = 0.5.  */
    real w = betaIncomplete( 0.5L*b, 0.5L*a, 0.5L );
    /* If that is greater than p, then the solution w < .5.
       Otherwise, solve at 1-p to remove cancellation in (b - b*w).  */
    if ( w > p || p < 0.001L) {
        w = betaIncompleteInv( 0.5L*b, 0.5L*a, p );
        return (b - b*w)/(a*w);
    } else {
        w = betaIncompleteInv( 0.5L*a, 0.5L*b, 1.0L - p );
        return b*w/(a*(1.0L-w));
    }
}

unittest {
// fDistCompl(df1, df2, x) = Excel's FDIST(x, df1, df2)
  assert(fabs(fDistributionCompl(6, 4, 16.5) - 0.00858719177897249L)< 0.0000000000005L);
  assert(fabs((1-fDistribution(12, 23, 0.1)) - 0.99990562845505L)< 0.0000000000005L);
  assert(fabs(fDistributionComplInv(8, 34, 0.2) - 1.48267037661408L)< 0.0000000005L);
  assert(fabs(fDistributionComplInv(4, 16, 0.008) - 5.043_537_593_48596L)< 0.0000000005L);
  // Regression test: This one used to fail because of a bug in the definition of MINLOG.
  assert(feqrel(fDistributionCompl(4, 16, fDistributionComplInv(4,16, 0.008)), 0.008)>=real.mant_dig-3);
}
