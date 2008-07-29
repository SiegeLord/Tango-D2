/** Fundamental operations for arbitrary-precision arithmetic
 *
 */

module tango.math.impl.BiguintCore;

version(GNU) {
    // GDC lies about its X86 support
public import tango.math.impl.BignumNoAsm;    
} else version(D_InlineAsm_X86) { 
public import tango.math.impl.BignumX86;
} else {
public import tango.math.impl.BignumNoAsm;
}

private:
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

public:
    
// Returns the highest value of i for which left[i]!=right[i],
// or 0 if left[]==right[]
int lastDifferentDigit(uint [] left, uint [] right)
{
    assert(left.length == right.length);
    for (int i=left.length; i>0; --i) {
        if (left[i]!=right[i]) return i;
    }
    return 0;
}

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
            if (c!=0) { data[hi]=c; ++hi; }
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
        if (hi==0)  { *cast(ulong *)(&data[hi]) = y; hi=2; }
        else {

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
            hi+=2;
        }
    }    
    return hi;
}

private:
// classic 'schoolbook' multiplication.
void mulSimple(uint[] result, uint [] left, uint[] right)
in {    
    assert(result.length == left.length + right.length);
    assert(right.length>1);
}
body {
    result[left.length] = multibyteMul(result[0..left.length], left, right[0], 0);
    if (right.length>1)
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
   assert(result.length > right.length);
   uint c = multibyteAddSub!('+')(result[0..right.length], result[0..right.length], right, 0);
   if (c) c = multibyteIncrementAssign!('+')(result[right.length .. $], c);
   assert(c==0);
}

// Limits for when to switch between multiplication algorithms.
const int CACHELIMIT = 8000;   // Half the size of the data cache.

/* Determine how much space is required for the temporaries
 * when performing a Karatsuba multiplication. 
 */
uint karatsubaRequiredBuffSize(uint xlen)
{
    return xlen <= KARATSUBALIMIT ? 0 : xlen * 2;
}

/* Sets result = x*y, using Karatsuba multiplication.
* Valid only for balanced multiplies, and x must be longer than y.
* ie 2*y.length > x.length >= y.length.
* Params:
* scratchbuff      An array long enough to store all the temporaries. Will be destroyed.
*/
void mulKaratsuba(uint [] result, uint [] x, uint[] y, uint [] scratchbuff)
{
    assert(result.length == x.length + y.length);
    assert(x.length >= y.length);
    if (x.length <= KARATSUBALIMIT) {
        return mulSimple(result, x, y);
    }    
    // Karatsuba multiply uses the following result:
    // (Nx1 + x0)*(Ny1 + y0) = (N*N) x1y1 + x0y0 + N * mid
    // where mid = (x1+x0)*(y1+y0) - x1y1 - x0y0
    // requiring 3 multiplies of length N, instead of 4.

    // half length, round up.
    uint half = (x.length >> 1) + (x.length & 1);
    assert(y.length>half, "Asymmetric Karatsuba");
    
    uint [] x0 = x[0 .. half];
    uint [] x1 = x[half .. $];    
    uint [] y0 = y[0 .. half];
    uint [] y1 = y[half .. $];
    uint [] xsum = result[0 .. half]; // initially use result to store temporaries
    uint [] ysum = result[half .. half*2];
    uint [] mid = scratchbuff[0 .. half*2+1];
    uint [] newscratchbuff = scratchbuff[half*2+2 .. $];
    uint [] resultLow = result[0 .. x0.length + y0.length];
    uint [] resultHigh = result[x0.length + y0.length .. $];
        
    // Add the high and low parts of x and y.
    // This will generate carries of either 0 or 1.
    uint carry_x = addSimple(xsum, x0, x1);
    uint carry_y = addSimple(ysum, y0, y1);
    
    mulKaratsuba(mid[0..half*2], xsum, ysum, newscratchbuff);
    mid[half*2] = carry_x & carry_y;
    if (carry_x)  simpleAddAssign(mid[half..$], ysum);
    if (carry_y)  simpleAddAssign(mid[half..$], xsum);
    
    // Low half of result gets x0 * y0. High half gets x1 * y1
   
    mulKaratsuba(resultLow, x0, y0, newscratchbuff);
    mid.simpleSubAssign(resultLow);
    mulKaratsuba(resultHigh, x1, y1, newscratchbuff);
    mid.simpleSubAssign(resultHigh);
    
    // result += MID
    result[half..$].simpleAddAssign(mid);
}

public:
    
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
        if (x.length * y.length < CACHELIMIT) return mulSimple(result, x, y);
        
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
    if (y.length <= half) {
        // UNBALANCED MULTIPLY
        // Use school multiply to cut into Karatsuba-sized squares,
        // unless y is so small that Karatsuba isn't worthwhile.
        // unbalanced case - use school multiply to cut into chunks, each sized 
        // y.length * y.length. Use Karatsuba on each chunk.
        // TODO: It _might_ be better to use non-square chunks (and have fewer chunks).
        
        // The first chunk is bigger, since it also needs to cover the leftover bits.
        uint chunksize =  y.length + (x.length % y.length);
        // We make the buffer a bit bigger so we have space for the partial sums.
        uint [] scratchbuff = new uint[karatsubaRequiredBuffSize(chunksize) + y.length * 2];
        if (y.length == half) {
            chunksize = x.length - y.length;
            mulKaratsuba(result[0 .. y.length + chunksize], y, x[0 .. chunksize], scratchbuff);
        } else {
            mulKaratsuba(result[0 .. y.length + chunksize], x[0 .. chunksize], y, scratchbuff);
        }
        uint done = chunksize;
        uint [] partial = scratchbuff[$-y.length*2 .. $];
        while (done < x.length) {
            chunksize = (done + y.length <= x.length) ? y.length :  x.length - done;
            mulKaratsuba(partial[0 .. y.length + chunksize], x[done .. done+chunksize], y, scratchbuff);
            result[done + y.length .. done + y.length + chunksize] 
                = partial[y.length .. y.length + chunksize];
            simpleAddAssign(result[done .. y.length + chunksize], partial[0 .. y.length]);
            done += y.length;
        }
       //delete scratchbuff;
    } else {
        // Balanced. Use Karatsuba directly.
        uint [] scratchbuff = new uint[karatsubaRequiredBuffSize(x.length)];
        mulKaratsuba(result, x, y, scratchbuff);
       // delete scratchbuff;
    }
}
