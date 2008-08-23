/** Fundamental operations for arbitrary-precision arithmetic
 *
 * Copyright: Copyright (C) 2008 Don Clugston.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 */
 
module tango.math.internal.BiguintCore;

version(TangoBignumNoAsm) {
private import tango.math.internal.BignumNoAsm;    
} else version(GNU) {
    // GDC lies about its X86 support
private import tango.math.internal.BignumNoAsm;    
} else version(D_InlineAsm_X86) { 
private import tango.math.internal.BignumX86;
} else {
private import tango.math.internal.BignumNoAsm;
}

private:
/*invariant */ uint [1] BIGINTZERO = [0];
public:

// return 1 if x>y, -1 if x<y, 0 if equal
int biguintCompare(uint [] x, uint []y)
{
    uint k = highestDifferentDigit(x, y);
    if (x[k] == y[k]) return 0;
    return x[k] > y[k] ? 1 : -1;
}

// return x >> y
uint [] biguintShr(uint[] x, ulong y)
{
    assert(y>0);
    uint bits = cast(uint)y & 31;
    if ((y>>5) >= x.length) return BIGINTZERO;
    uint words = cast(uint)(y >> 5);
    if (bits==0) {
        return x[words..$];
    } else {
        uint [] result = new uint[x.length - words];
        multibyteShr(result, x[words..$], bits);
        if (result.length>1 && result[$-1]==0) return result[0..$-1];
        else return result;
    }
}

// return x << y
uint [] biguintShl(uint[] x, ulong y)
{
    assert(y>0);
    if (x.length==1 && x[0]==0) return x;
    uint bits = cast(uint)y & 31;
    assert ((y>>5) < cast(ulong)(uint.max));
    uint words = cast(uint)(y >> 5);
    uint [] result = new uint[x.length + words+1];
    result[0..words] = 0;
    if (bits==0) {
        result[words..words+x.length] = x[];
        return result[0..words+x.length];
    } else {
        uint c = multibyteShl(result[words..words+x.length], x, bits);
        if (c==0) return result[0..words+x.length];
        result[$-1] = c;
        return result;
    }
}

/** General unsigned subtraction routine for bigints.
 *  Sets result = x - y. If the result is negative, negative will be true.
 */
uint [] biguintSub(uint[] x, uint[] y, bool *negative)
{
    if (x.length == y.length) {
        // There's a possibility of cancellation, if x and y are almost equal.
        int last = highestDifferentDigit(x, y);
        uint [] result = new uint[last+1];
        if (x[last] < y[last]) { // we know result is negative
            multibyteAddSub!('-')(result[0..last+1], y[0..last+1], x[0..last+1], 0);
            *negative = true;
        } else { // positive or zero result
            multibyteAddSub!('-')(result[0..last+1], x[0..last+1], y[0..last+1], 0);
            *negative = false;
        }
        if (result.length >1 && result[$-1]==0) return result[0..$-1];
        return result;
    }
    // Lengths are different
    uint [] large, small;
    if (x.length < y.length) {
        *negative = true;
        large = y; small = x;
    } else {
        *negative = false;
        large = x; small = y;
    }
    // result.length will be equal to larger length, or could decrease by 1.
    
    uint [] result = new uint[large.length];
    uint carry = multibyteAddSub!('-')(result[0..small.length], large[0..small.length], small, 0);
    result[small.length..$] = large[small.length..$];
    if (carry) {
        multibyteIncrementAssign!('-')(result[small.length..$-1], carry);
    }
    if (result.length >1 && result[$-1]==0) return result[0..$-1];
    return result;
}

// return a + b
uint [] biguintAdd(uint[] a, uint [] b) {
    uint [] x, y;
    if (a.length<b.length) { x = b; y = a; } else { x = a; y = b; }
    // now we know x.length > y.length
    // create result. add 1 in case it overflows
    uint [] result = new uint[x.length + 1];
    
    uint carry = multibyteAddSub!('+')(result[0..y.length], x[0..y.length], y, 0);
    if (x.length != y.length){
        result[y.length..$-1]= x[y.length..$];
        carry  = multibyteIncrementAssign!('+')(result[y.length..$-1], carry);
    }
    if (carry) {
        result[$-1] = carry;
        return result;
    } else return result[0..$-1];
}


/** return x+y
 */
uint [] biguintAddInt(uint[] x, ulong y)
{
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y& 0xFFFF_FFFF);
    uint len = x.length;
    if (x.length < 2 && hi!=0) ++len;
    uint [] result = new uint[len+1];
    result[0..x.length] = x[]; 
    if (x.length < 2 && hi!=0) { result[1]=hi; hi=0; }
    uint carry = multibyteIncrementAssign!('+')(result[0..$-1], lo);
    if (hi!=0) carry += multibyteIncrementAssign!('+')(result[1..$-1], hi);
    if (carry) {
        result[$-1] = carry;
        return result;
    } else return result[0..$-1];
}

/** Return x-y..
 *  x must be greater than y.
 */  
uint [] biguintSubInt(uint[] x, ulong y)
{
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y& 0xFFFF_FFFF);
    uint [] result = new uint[x.length];
    result[] = x[];
    multibyteIncrementAssign!('-')(result[], lo);
    if (hi) multibyteIncrementAssign!('-')(result[1..$], hi);
    if (result[$-1]==0) return result[0..$-1];
    else return result; 
}

/** return x*y.
 *  y must not be zero.
 */
uint [] biguintMulInt(uint [] x, ulong y)
{
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y & 0xFFFF_FFFF);
    uint [] result = new uint[x.length+1+(hi!=0)];
    result[x.length] = multibyteMul(result[0..x.length], x, lo, 0);
    if (hi!=0) {
        result[x.length+1] = multibyteMulAdd!('+')(result[1..x.length+1], x, hi, 0);
    }
    return result;
}

/** General unsigned multiply routine for bigints.
 *  Sets result = x*y.
 *
 *  The length of y must not be larger than the length of x.
 *  Different algorithms are used, depending on the lengths of x and y.
 * 
 */
void biguintMul(uint[] result, uint[] x, uint[] y)
{
    assert( result.length == x.length + y.length );
    assert( y.length > 0 );
    assert( x.length >= y.length);
    if (y.length <= KARATSUBALIMIT) {
        // Small multiplier, we'll just use the asm classic multiply.
        if (y.length==1) { // Trivial case, no cache effects to worry about
            result[x.length] = multibyteMul(result[0..x.length], x, y[0], 0);
            return;
        }
        if (x.length + y.length < CACHELIMIT) return mulSimple(result, x, y);
        
        // If x is so big that it won't fit into the cache, we divide it into chunks            
        // Every chunk must be greater than y.length.
        // We make the first chunk shorter, if necessary, to ensure this.
        
        uint chunksize = CACHELIMIT/y.length;
        uint residual  =  x.length % chunksize;
        if (residual < y.length) { chunksize -= y.length; }
        // Use schoolbook multiply.
        mulSimple(result[0 .. chunksize + y.length], x[0..chunksize], y);
        uint done = chunksize;        
    
        while (done < x.length) {            
            // result[done .. done+ylength] already has a value.
            chunksize = (done + (CACHELIMIT/y.length) < x.length) ? (CACHELIMIT/y.length) :  x.length - done;
            uint [KARATSUBALIMIT] partial;
            partial[0..y.length] = result[done..done+y.length];
            mulSimple(result[done..done+chunksize+y.length], x[done..done+chunksize], y);
            simpleAddAssign(result[done..done+chunksize + y.length], partial[0..y.length]);
            done += chunksize;
        }
        return;
    }
    
    uint half = (x.length >> 1) + (x.length & 1);
    if (2*y.length*y.length <= x.length*x.length) {
        // UNBALANCED MULTIPLY
        // Use school multiply to cut into quasi-squares of Karatsuba-size
        // or larger. The ratio of the two sides of the 'square' must be 
        // between 1.414:1 and 1:1. Use Karatsuba on each chunk. 
        //
        // For maximum performance, we want the ratio to be as close to 
        // 1:1 as possible. To achieve this, we can either pad x or y.
        // The best choice depends on the modulus x%y.       
        uint numchunks = x.length / y.length;
        uint chunksize = y.length;
        uint extra =  x.length % y.length;
        uint maxchunk = chunksize + extra;
        bool paddingY; // true = we're padding Y, false = we're padding X.
        if (extra * extra * 2 < y.length*y.length) {
            // The leftover bit is small enough that it should be incorporated
            // in the existing chunks.            
            // Make all the chunks a tiny bit bigger
            // (We're padding y with zeros)
            chunksize += extra / cast(double)numchunks;
            extra = x.length - chunksize*numchunks;
            // there will probably be a few left over.
            // Every chunk will either have size chunksize, or chunksize+1.
            maxchunk = chunksize + 1;
            paddingY = true;
            assert(chunksize + extra + chunksize *(numchunks-1) == x.length );
        } else  {
            // the extra bit is large enough that it's worth making a new chunk.
            // (This means we're padding x with zeros, when doing the first one).
            maxchunk = chunksize;
            ++numchunks;
            paddingY = false;
            assert(extra + chunksize *(numchunks-1) == x.length );
        }
        // We make the buffer a bit bigger so we have space for the partial sums.
        uint [] scratchbuff = new uint[karatsubaRequiredBuffSize(maxchunk) + y.length];
        uint [] partial = scratchbuff[$ - y.length .. $];
        uint done; // how much of X have we done so far?
        double residual = 0;
        if (paddingY) {
            // If the first chunk is bigger, do it first. We're padding y. 
          mulKaratsuba(result[0 .. y.length + chunksize + (extra > 0 ? 1 : 0 )], 
                        x[0 .. chunksize + (extra>0?1:0)], y, scratchbuff);
          done = chunksize + (extra > 0 ? 1 : 0);
          if (extra) --extra;
        } else { // Begin with the extra bit.
            mulKaratsuba(result[0 .. y.length + extra], y, x[0..extra], scratchbuff);
            done = extra;
            extra = 0;
        }
        auto basechunksize = chunksize;
        while (done < x.length) {
            chunksize = basechunksize + (extra > 0 ? 1 : 0);
            if (extra) --extra;
            partial[] = result[done .. done+y.length];
            mulKaratsuba(result[done .. done + y.length + chunksize], 
                       x[done .. done+chunksize], y, scratchbuff);
            simpleAddAssign(result[done .. done + y.length + chunksize], partial);
            done += chunksize;
        }
        delete scratchbuff;
    } else {
        // Balanced. Use Karatsuba directly.
        uint [] scratchbuff = new uint[karatsubaRequiredBuffSize(x.length)];
        mulKaratsuba(result, x, y, scratchbuff);
        delete scratchbuff;
    }
}

// return x/y
uint[] biguintDivInt(uint [] x, uint y) {
    uint [] result = new uint[x.length];
    if ((y&(-y))==y) {
        assert(y!=0);
        // perfect power of 2
        uint b = 0;
        for (;y!=0; y>>=1) {
            ++b;
        }
        multibyteShr(result, x, b);
    } else {
        result[] = x[];
        uint rem = multibyteDivAssign(result, y, 0);
    }
    if (result[$-1]==0 && result.length>1) {
        return result[0..$-1];
    } else return result;
}

// return x%y
uint biguintModInt(uint [] x, uint y) {
    assert(y!=0);
    if (y&(-y)==y) { // perfect power of 2        
        return x[0]&(y-1);   
    } else {
        // horribly inefficient - malloc, copy, & store are unnecessary.
        uint [] wasteful = new uint[x.length];
        wasteful[] = x[];
        uint rem = multibyteDivAssign(wasteful, y, 0);
        delete wasteful;
        return rem;
    }   
}

uint [] biguintDiv(uint [] x, uint [] y)
{
    if (y.length > x.length) return BIGINTZERO;
    if (y.length == 1) return biguintDivInt(x, y[0]);
    uint [] result = new uint[x.length - y.length + 1];
    schoolbookDivMod(result, null, x, y);
    if (result.length>1 && result[$-1]==0) result=result[0..$-1];
    return result;
}

uint [] biguintMod(uint [] x, uint [] y)
{
    if (y.length > x.length) return x;
    if (y.length == 1) return biguintDivInt(x, y[0]);
    uint [] result = new uint[x.length - y.length + 1];
    uint [] rem = new uint[y.length];
    schoolbookDivMod(result, rem, x, y);
    while (rem.length>1 && rem[$-1]==0) rem = rem[0..$-1];
    return rem;
}

public:
// Converts a big uint to a hexadecimal string.
//
// Optionally, a separator character (eg, an underscore) may be added between
// every 8 digits.
// buff.length must be data.length*8 if separator is zero,
// or data.length*9 if separator is non-zero. It will be completely filled.
char [] biguintToHex(char [] buff, uint [] data, char separator=0)
{
    int x=0;
    for (int i=data.length - 1; i>=0; --i) {
        toHexZeroPadded(buff[x..x+8], data[i]);
        x+=8;
        if (separator) {
            if (i>0) buff[x]='_';
            ++x;
        }
    }
    return buff;
}

/** Convert a big uint into a decimal string.
 *
 * Params:
 *  data    The biguint to be converted. Will be destroyed.
 *  buff    The destination buffer for the decimal string. Must be
 *          large enough to store the result, including leading zeros.
 *          Will be filled starting from the end.
 *
 * Ie, buff.length must be (data.length*32)/log2(10) = 9.63296 * data.length.
 * Returns:
 *    the lowest index of buff which was used.
 */
int biguintToDecimal(char [] buff, uint [] data){
    int sofar = buff.length;
    // Might be better to divide by (10^38/2^32) since that gives 38 digits for
    // the price of 3 divisions and a shr; this version only gives 27 digits
    // for 3 divisions.
    while(data.length>1) {
        uint rem = multibyteDivAssign(data, 10_0000_0000, 0);
        itoaZeroPadded(buff[sofar-9 .. sofar], rem);
        sofar -= 9;
        if (data[$-1]==0 && data.length>1) {
            data.length = data.length - 1;
        }
    }
    itoaZeroPadded(buff[sofar-10 .. sofar], data[0]);
    sofar-=10;
    // and strip off the leading zeros
    while(sofar!= buff.length-1 && buff[sofar] == '0') sofar++;    
    return sofar;
}

/** Convert a decimal string into a big uint.
 *
 * Params:
 *  data    The biguint to be receive the result. Must be large enough to 
 *          store the result.
 *  s       The decimal string. May contain 0..9, or _. Will be preserved.
 *
 * The required length for the destination buffer is slightly less than
 *  1 + s.length/log2(10) = 1 + s.length/3.3219.
 *
 * Returns:
 *    the highest index of data which was used.
 */
int biguintFromDecimal(uint [] data, char [] s) {
    // Convert to base 1e19 = 10_000_000_000_000_000_000.
    // (this is the largest power of 10 that will fit into a long).
    // The length will be less than 1 + s.length/log2(10) = 1 + s.length/3.3219.
    // 485 bits will only just fit into 146 decimal digits.
    uint lo = 0;
    uint x = 0;
    ulong y = 0;
    uint hi = 0;
    data[0] = 0; // initially number is 0.
    data[1]=0;    
   
    for (int i= (s[0]=='-' || s[0]=='+')? 1 : 0; i<s.length; ++i) {            
        if (s[i] == '_') continue;
        x *= 10;
        x += s[i] - '0';
        ++lo;
        if (lo==9) {
            y = x;
            x = 0;
        }
        if (lo==18) {
            y *= 10_0000_0000;
            y += x;
            x = 0;
        }
        if (lo==19) {
            y *= 10;
            y += x;
            x = 0;
            // Multiply existing number by 10^19, then add y1.
            if (hi>0) {
                data[hi] = multibyteMul(data[0..hi], data[0..hi], 1220703125*2, 0); // 5^13*2 = 0x9184_E72A
                ++hi;
                data[hi] = multibyteMul(data[0..hi], data[0..hi], 15625*262144, 0); // 5^6*2^18 = 0xF424_0000
                ++hi;
            } else hi = 2;
            uint c = multibyteIncrementAssign!('+')(data[0..hi], cast(uint)(y&0xFFFF_FFFF));
            c += multibyteIncrementAssign!('+')(data[1..hi], cast(uint)(y>>32));
            if (c!=0) {
                data[hi]=c;
                ++hi;
            }
            y = 0;
            lo = 0;
        }
    }
    // Now set y = all remaining digits.
    if (lo>=18) {
    } else if (lo>=9) {
        for (int k=9; k<lo; ++k) y*=10;
        y+=x;
    } else {
        for (int k=0; k<lo; ++k) y*=10;
        y+=x;
    }
    if (y!=0) {
        if (hi==0)  {
            *cast(ulong *)(&data[hi]) = y;
            hi=2;
        } else {
            while (lo>0) {
                uint c = multibyteMul(data[0..hi], data[0..hi], 10, 0);
                if (c!=0) { data[hi]=c; ++hi; }                
                --lo;
            }
            uint c = multibyteIncrementAssign!('+')(data[0..hi], cast(uint)(y&0xFFFF_FFFF));
            if (y>0xFFFF_FFFFL) {
                c += multibyteIncrementAssign!('+')(data[1..hi], cast(uint)(y>>32));
            }
            if (c!=0) { data[hi]=c; ++hi; }
          //  hi+=2;
        }
    }
    if (hi>1 && data[hi-1]==0) --hi;
    return hi;
}


private:
// ------------------------
// These in-place functions are only for internal use; they are incompatible
// with COW.

// Classic 'schoolbook' multiplication.
void mulSimple(uint[] result, uint [] left, uint[] right)
in {    
    assert(result.length == left.length + right.length);
    assert(right.length>1);
}
body {
    result[left.length] = multibyteMul(result[0..left.length], left, right[0], 0);
    multibyteMultiplyAccumulate(result[1..$], left, right[1..$]);
}


// add two uints of possibly different lengths. Result must be as long
// as the larger length.
uint addSimple(uint [] result, uint [] left, uint [] right)
in {
    assert(result.length == left.length);
    assert(left.length >= right.length);
    assert(right.length>0);
}
body {
    uint carry = multibyteAddSub!('+')(result[0..right.length],
            left[0..right.length], right, 0);
    if (right.length < left.length) {
        result[right.length..left.length] = left[right.length .. $];            
        carry = multibyteIncrementAssign!('+')(result[right.length..$], carry);
    }
    return carry;
}

uint subSimple(uint [] result, uint [] left, uint [] right)
in {
    assert(result.length == left.length);
    assert(left.length >= right.length);
    assert(right.length>0);
}
body {
    uint carry = multibyteAddSub!('-')(result[0..right.length],
            left[0..right.length], right, 0);
    if (right.length < left.length) {
        result[right.length..left.length] = left[right.length .. $];            
        carry = multibyteIncrementAssign!('-')(result[right.length..$], carry);
    } //else if (result.length==left.length+1) { result[$-1] = carry; carry=0; }
    return carry;
}


/*  result must be larger than right.
*/
void simpleSubAssign(uint [] result, uint [] right)
{
    assert(result.length > right.length);
    uint c = multibyteAddSub!('-')(result[0..right.length], result[0..right.length], right, 0); 
    if (c) c = multibyteIncrementAssign!('-')(result[right.length .. $], c);
    assert(c==0);
}


void simpleAddAssign(uint [] result, uint [] right)
{
   assert(result.length >= right.length);
   uint c = multibyteAddSub!('+')(result[0..right.length], result[0..right.length], right, 0);
   if (c) {
   assert(result.length > right.length);
       c = multibyteIncrementAssign!('+')(result[right.length .. $], c);
       assert(c==0);
   }
}

// Limits for when to switch between multiplication algorithms.
const int CACHELIMIT = 8000;   // Half the size of the data cache.

/* Determine how much space is required for the temporaries
 * when performing a Karatsuba multiplication. 
 */
uint karatsubaRequiredBuffSize(uint xlen)
{
    return xlen <= KARATSUBALIMIT ? 0 : 2*xlen - KARATSUBALIMIT + 2*uint.sizeof*8;
}

/* Sets result = x*y, using Karatsuba multiplication.
* x must be longer or equal to y.
* Valid only for balanced multiplies, where x is not shorter than y.
* It is efficient only if sqrt(2)*y.length > x.length >= y.length.
* Karatsuba multiplication is O(n^1.59), whereas schoolbook is O(n^2)
* Params:
* scratchbuff      An array long enough to store all the temporaries. Will be destroyed.
*/
void mulKaratsuba(uint [] result, uint [] x, uint[] y, uint [] scratchbuff)
{
    assert(result.length == x.length + y.length);
    assert(x.length >= y.length);
    if (y.length <= KARATSUBALIMIT) {
        return mulSimple(result, x, y);
    }
    // Must be almost square.
    assert(2 * y.length * y.length > (x.length-1) * (x.length-1), "Asymmetric Karatsuba");
        
    // Karatsuba multiply uses the following result:
    // (Nx1 + x0)*(Ny1 + y0) = (N*N) x1y1 + x0y0 + N * mid
    // where mid = (x1+x0)*(y1+y0) - x1y1 - x0y0
    // requiring 3 multiplies of length N, instead of 4.
    

    // half length, round up.
    uint half = (x.length >> 1) + (x.length & 1);
    
    uint [] x0 = x[0 .. half];
    uint [] x1 = x[half .. $];    
    uint [] y0 = y[0 .. half];
    uint [] y1 = y[half .. $];
    uint [] xsum = result[0 .. half]; // initially use result to store temporaries
    uint [] ysum = result[half .. half*2];
    uint [] mid = scratchbuff[0 .. half*2+1];
    uint [] newscratchbuff = scratchbuff[half*2+1 .. $];
    uint [] resultLow = result[0 .. x0.length + y0.length];
    uint [] resultHigh = result[x0.length + y0.length .. $];
        
    
    // Add the high and low parts of x and y.
    // This will generate carries of either 0 or 1.
    // TODO: Knuth's variant would save the extra two additions:
    // (Nx1 + x0)*(Ny1 + y0) = (N*N) x1y1 + x0y0 - N * mid
    // where mid = (x0-x1)*(y0-y1) - x1y1 - x0y0
    // since then mid.length cannot exceed length N.
    uint carry_x = addSimple(xsum, x0, x1);
    uint carry_y = addSimple(ysum, y0, y1);
    
    mulKaratsuba(mid[0..half*2], xsum, ysum, newscratchbuff);
    mid[half*2] = carry_x & carry_y;
    if (carry_x)  simpleAddAssign(mid[half..$], ysum);
    if (carry_y)  simpleAddAssign(mid[half..$], xsum);
    // Low half of result gets x0 * y0. High half gets x1 * y1
   
    mulKaratsuba(resultLow, x0, y0, newscratchbuff);
    mid.simpleSubAssign(resultLow);

    if (2 * y1.length * y1.length < x1.length * x1.length) {
        // an asymmetric situation has been created.
        // Worst case is if x:y = 1.414 : 1, then x1:y1 = 2.41 : 1.
        // Applying one schoolbook multiply gives us two pieces each 1.2:1
        if (y1.length <= KARATSUBALIMIT) {
            mulSimple(resultHigh, x1, y1);
        } else {
            // divide x1 in two, then use schoolbook multiply on the two pieces.
            uint quarter = (x1.length >> 1) + (x1.length & 1);
            bool ysmaller = (quarter >= y1.length);
            mulKaratsuba(resultHigh[0..quarter+y1.length], ysmaller?x1[0..quarter]: y1, 
                ysmaller?y1:x1[0..quarter], newscratchbuff);
            // Save the part which will be overwritten.
            bool ysmaller2 = ((x1.length -quarter) >= y1.length);
            newscratchbuff[0..y1.length] = resultHigh[quarter..quarter+y1.length];
            mulKaratsuba(resultHigh[quarter..$], ysmaller2?x1[quarter..$]: y1, 
                ysmaller2?y1:x1[quarter..$], newscratchbuff[y1.length..$]);

            resultHigh[quarter..$].simpleAddAssign(newscratchbuff[0..y1.length]);                
        }
    } else mulKaratsuba(resultHigh, x1, y1, newscratchbuff);
        
    mid.simpleSubAssign(resultHigh);

    // result += MID
    result[half..$].simpleAddAssign(mid);
}

import std.intrinsic;


/* Knuth's Algorithm D, as presented in "Hacker's Delight"
* given u and v, calculates  quotient  = u/v, remainder = u%v.
*/
//import tango.stdc.stdio;

// given u and v, calculates  quotient  = u/v, remainder = u%v.
void schoolbookDivMod(uint [] quotient, uint[] remainder, uint [] u, uint [] v) {
    assert(quotient.length == u.length - v.length + 1);
    assert(remainder==null || remainder.length == v.length);
    assert(v.length > 1);
    assert(u.length >= v.length);
    assert(v[$-1]!=0);

    // Normalize by shifting v left just enough so that
    // its high-order bit is on, and shift u left the
    // same amount.
   
    uint [] vn = new uint[v.length];
    uint [] un = new uint[u.length + 1];
    // How much to left shift v, so that its MSB is set.
    uint s = 31 - bsr(v[$-1]);
    multibyteShl(vn, v, s);   
    un[$-1] = multibyteShl(un[0..$-1], u, s);
    for (int j = u.length - v.length; j >= 0; j--) {
        // Compute estimate qhat of quotient[j].
        ulong bigqhat, rhat;
        bigqhat = ( (cast(ulong)(un[j+v.length])<<32) + un[j+v.length-1])/vn[$-1];
        rhat = ((cast(ulong)(un[j+v.length])<<32) + un[j+v.length-1]) - bigqhat*vn[$-1];
again:
        if (bigqhat & 0xFFFF_FFFF_0000_0000L 
            || bigqhat*vn[$-2] > 0x1_0000_0000L*rhat + un[j+v.length-2]) {
            --bigqhat;
            rhat += vn[$-1];
            if (rhat < 0x1_0000_0000L) goto again;
        }
        assert(bigqhat < 0x1_0000_0000L);
        uint qhat = cast(uint)bigqhat;

        // Multiply and subtract.
        uint carry = multibyteMulAdd!('-')(un[j..j+v.length], vn, qhat, 0);

        if (un[j+v.length] < carry) {
            // If we subtracted too much, add back
            --qhat;
            carry -= multibyteAddSub!('+')(un[j..j+v.length],un[j..j+v.length], vn, 0);
        }
        quotient[j] = qhat;
        un[j+v.length] = un[j+v.length] - carry;
        assert(un[j+v.length] == 0);
    }
    // Unnormalize remainder, if required.
    if (remainder != null) {
         multibyteShr(remainder, un, s);
    }
}

private:
// TODO: Replace with a library call
void itoaZeroPadded(char[] output, uint value, int radix = 10) {
    int x = output.length - 1;
    for( ; x>=0; --x) {
        output[x]= value % radix + '0';
        value /= radix;
    }
}

void toHexZeroPadded(char[] output, uint value) {
    int x = output.length - 1;
    const char [] hexDigits = "0123456789ABCDEF";
    for( ; x>=0; --x) {        
        output[x] = hexDigits[value & 0xF];
        value >>>= 4;        
    }
}

private:
    
// Returns the highest value of i for which left[i]!=right[i],
// or 0 if left[]==right[]
int highestDifferentDigit(uint [] left, uint [] right)
{
    assert(left.length == right.length);
    for (int i=left.length-1; i>0; --i) {
        if (left[i]!=right[i]) return i;
    }
    return 0;
}
