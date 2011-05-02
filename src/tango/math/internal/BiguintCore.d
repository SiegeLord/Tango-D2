/** Fundamental operations for arbitrary-precision arithmetic
 *
 * These functions are for internal use only.
 *
 * Copyright: Copyright (C) 2008 Don Clugston.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 */
/* References:
  - R.P. Brent and P. Zimmermann, "Modern Computer Arithmetic", 
    Version 0.2, p. 26, (June 2009).
  - C. Burkinel and J. Ziegler, "Fast Recursive Division", MPI-I-98-1-022, 
    Max-Planck Institute fuer Informatik, (Oct 1998).
  - G. Hanrot, M. Quercia, and P. Zimmermann, "The Middle Product Algorithm, I.",
    INRIA 4664, (Dec 2002).
  - M. Bodrato and A. Zanoni, "What about Toom-Cook Matrices Optimality?",
    http://bodrato.it/papers (2006).
  - A. Fog, "Optimizing subroutines in assembly language", 
    www.agner.org/optimize (2008).
  - A. Fog, "The microarchitecture of Intel and AMD CPU's",
    www.agner.org/optimize (2008).
  - A. Fog, "Instruction tables: Lists of instruction latencies, throughputs
    and micro-operation breakdowns for Intel and AMD CPU's.", www.agner.org/optimize (2008).
*/ 
module tango.math.internal.BiguintCore;

//version=TangoBignumNoAsm;       /// temporal: see ticket #1878

version(GNU){
    // GDC is a filthy liar. It can't actually do inline asm.
} else version(TangoBignumNoAsm) {

} else version(D_InlineAsm_X86) {
    version = Naked_D_InlineAsm_X86;
} else version(LLVM_InlineAsm_X86) { 
    version = Naked_D_InlineAsm_X86; 
}

version(Naked_D_InlineAsm_X86) { 
private import tango.math.internal.BignumX86;
} else {
private import tango.math.internal.BignumNoAsm;
}
version(build){// bud/build won't link properly without this.
    static import tango.math.internal.BignumX86;
}

alias multibyteAddSub!('+') multibyteAdd;
alias multibyteAddSub!('-') multibyteSub;

// private import tango.core.Cpuid;
static this()
{
    CACHELIMIT = 8000; // tango.core.Cpuid.datacache[0].size/2;
    FASTDIVLIMIT = 100;
}

private:
// Limits for when to switch between algorithms.
const int CACHELIMIT;   // Half the size of the data cache.
const int FASTDIVLIMIT; // crossover to recursive division


// These constants are used by shift operations
static if (BigDigit.sizeof == int.sizeof) {
    enum { LG2BIGDIGITBITS = 5, BIGDIGITSHIFTMASK = 31 };
    alias ushort BIGHALFDIGIT;
} else static if (BigDigit.sizeof == long.sizeof) {
    alias uint BIGHALFDIGIT;
    enum { LG2BIGDIGITBITS = 6, BIGDIGITSHIFTMASK = 63 };
} else static assert(0, "Unsupported BigDigit size");

const BigDigit [] ZERO = [0];
const BigDigit [] ONE = [1];
const BigDigit [] TWO = [2];
const BigDigit [] TEN = [10];

public:       

/// BigUint performs memory management and wraps the low-level calls.
struct BigUint {
private:
    invariant() {
        assert( data.length == 1 || data[$-1] != 0 );
    }
    BigDigit [] data = ZERO; 
    static BigUint opCall(BigDigit [] x) {
       BigUint a;
       a.data = x;
       return a;
    }
public: // for development only, will be removed eventually
    // Equivalent to BigUint[numbytes-$..$]
    BigUint sliceHighestBytes(uint numbytes) {
        BigUint x;
        x.data = data[$ - (numbytes>>2) .. $];
        return x;
    }
    // Length in uints
    int uintLength() {
        static if (BigDigit.sizeof == uint.sizeof) {
            return data.length;
        } else static if (BigDigit.sizeof == ulong.sizeof) {
            return data.length * 2 - 
            ((data[$-1] & 0xFFFF_FFFF_0000_0000L) ? 1 : 0);
        }
    }
    int ulongLength() {
        static if (BigDigit.sizeof == uint.sizeof) {
            return (data.length + 1) >> 1;
        } else static if (BigDigit.sizeof == ulong.sizeof) {
            return data.length;
        }
    }

    // The value at (cast(ulong[])data)[n]
    ulong peekUlong(int n) {
        static if (BigDigit.sizeof == int.sizeof) {
            if (data.length == n*2 + 1) return data[n*2];
            version(LittleEndian) {
                return data[n*2] + ((cast(ulong)data[n*2 + 1]) << 32 );
            } else {
                return data[n*2 + 1] + ((cast(ulong)data[n*2]) << 32 );
            }
        } else static if (BigDigit.sizeof == long.sizeof) {
            return data[n];
        }
    }
    uint peekUint(int n) {
        static if (BigDigit.sizeof == int.sizeof) {
            return data[n];
        } else {
            ulong x = data[n >> 1];
            return (n & 1) ? cast(uint)(x >> 32) : cast(uint)x;
        }
    }
public:
    ///
    void opAssign(ulong u) {
        if (u == 0) data = ZERO;
        else if (u == 1) data = ONE;
        else if (u == 2) data = TWO;
        else if (u == 10) data = TEN;
        else {
            uint ulo = cast(uint)(u & 0xFFFF_FFFF);
            uint uhi = cast(uint)(u >> 32);
            if (uhi==0) {
              data = new BigDigit[1];
              data[0] = ulo;
            } else {
              data = new BigDigit[2];
              data[0] = ulo;
              data[1] = uhi;
            }
        }
    }
    
    void opAssign(BigUint a)
    {
		data = a.data;
	}
    
///
int opCmp(BigUint y)
{
    if (data.length != y.data.length) {
        return (data.length > y.data.length) ?  1 : -1;
    }
    uint k = highestDifferentDigit(data, y.data);
    if (data[k] == y.data[k]) return 0;
    return data[k] > y.data[k] ? 1 : -1;
}

///
int opCmp(ulong y)
{
    if (data.length>2) return 1;
    uint ylo = cast(uint)(y & 0xFFFF_FFFF);
    uint yhi = cast(uint)(y >> 32);
    if (data.length == 2 && data[1] != yhi) {
        return data[1] > yhi ? 1: -1;
    }
    if (data[0] == ylo) return 0;
    return data[0] > ylo ? 1: -1;
}

const bool opEquals(const ref BigUint y) {
       return y.data[] == data[];
}

const bool opEquals(ulong y) {
    if (data.length>2) return 0;
    uint ylo = cast(uint)(y & 0xFFFF_FFFF);
    uint yhi = cast(uint)(y >> 32);
    if (data.length==2 && data[1]!=yhi) return 0;
    if (data.length==1 && yhi!=0) return 0;
    return (data[0] == ylo);
}


bool isZero() { return data.length == 1 && data[0] == 0; }

int numBytes() {
    return data.length * BigDigit.sizeof;
}

// the extra bytes are added to the start of the string
char [] toDecimalString(int frontExtraBytes)
{
    uint predictlength = 20+20*(data.length/2); // just over 19
    char [] buff = new char[frontExtraBytes + predictlength];
    int sofar = biguintToDecimal(buff, data.dup);       
    return buff[sofar-frontExtraBytes..$];
}

/** Convert to a hex string, printing a minimum number of digits 'minPadding',
 *  allocating an additional 'frontExtraBytes' at the start of the string.
 *  Padding is done with padChar, which may be '0' or ' '.
 *  'separator' is a digit separation character. If non-zero, it is inserted
 *  between every 8 digits.
 *  Separator characters do not contribute to the minPadding.
 */
char [] toHexString(int frontExtraBytes, char separator = 0, int minPadding=0, char padChar = '0')
{
    // Calculate number of extra padding bytes
    size_t extraPad = (minPadding > data.length * 2 * BigDigit.sizeof) 
        ? minPadding - data.length * 2 * BigDigit.sizeof : 0;

    // Length not including separator bytes                
    size_t lenBytes = data.length * 2 * BigDigit.sizeof;

    // Calculate number of separator bytes
    size_t mainSeparatorBytes = separator ? (lenBytes  / 8) - 1 : 0;
    size_t totalSeparatorBytes = separator ? ((extraPad + lenBytes + 7) / 8) - 1: 0;

    char [] buff = new char[lenBytes + extraPad + totalSeparatorBytes + frontExtraBytes];
    biguintToHex(buff[$ - lenBytes - mainSeparatorBytes .. $], data, separator);
    if (extraPad > 0) {
        if (separator) {
            size_t start = frontExtraBytes; // first index to pad
            if (extraPad &7) {
                // Do 1 to 7 extra zeros.
                buff[frontExtraBytes .. frontExtraBytes + (extraPad & 7)] = padChar;
                buff[frontExtraBytes + (extraPad & 7)] = (padChar == ' ' ? ' ' : separator);
                start += (extraPad & 7) + 1;
            }
            for (int i=0; i< (extraPad >> 3); ++i) {
                buff[start .. start + 8] = padChar;
                buff[start + 8] = (padChar == ' ' ? ' ' : separator);
                start += 9;
            }
        } else {
            buff[frontExtraBytes .. frontExtraBytes + extraPad]=padChar;
        }
    }
    int z = frontExtraBytes;
    if (lenBytes > minPadding) {
        // Strip leading zeros.
        int maxStrip = lenBytes - minPadding;
        while (z< buff.length-1 && (buff[z]=='0' || buff[z]==padChar) && maxStrip>0) {
            ++z; --maxStrip;
        }
    }
    if (padChar!='0') {
        // Convert leading zeros into padChars.
        for (size_t k= z; k< buff.length-1 && (buff[k]=='0' || buff[k]==padChar); ++k) {
            if (buff[k]=='0') buff[k]=padChar;
        }
    }
    return buff[z-frontExtraBytes..$];
}

// return false if invalid character found
bool fromHexString(const(char []) s)
{
    //Strip leading zeros
    int firstNonZero = 0;    
    while ((firstNonZero < s.length - 1) && 
        (s[firstNonZero]=='0' || s[firstNonZero]=='_')) {
            ++firstNonZero;
    }    
    int len = (s.length - firstNonZero + 15)/4;
    data = new BigDigit[len+1];
    uint part = 0;
    uint sofar = 0;
    uint partcount = 0;
    assert(s.length>0);
    for (int i = s.length - 1; i>=firstNonZero; --i) {
        assert(i>=0);
        char c = s[i];
        if (s[i]=='_') continue;
        uint x = (c>='0' && c<='9') ? c - '0' 
               : (c>='A' && c<='F') ? c - 'A' + 10 
               : (c>='a' && c<='f') ? c - 'a' + 10
               : 100;
        if (x==100) return false;
        part >>= 4;
        part |= (x<<(32-4));
        ++partcount;
        if (partcount==8) {
            data[sofar] = part;
            ++sofar;
            partcount = 0;
            part = 0;
        }
    }
    if (part) {
        for ( ; partcount != 8; ++partcount) part >>= 4;
        data[sofar] = part;
        ++sofar;
    }
    if (sofar == 0) data = ZERO;
    else data = data[0..sofar];
    return true;
}

// return true if OK; false if erroneous characters found
bool fromDecimalString(const(char []) s)
{
    //Strip leading zeros
    int firstNonZero = 0;    
    while ((firstNonZero < s.length - 1) && 
        (s[firstNonZero]=='0' || s[firstNonZero]=='_')) {
            ++firstNonZero;
    }
    if (firstNonZero == s.length - 1 && s.length > 1) {
        data = ZERO;
        return true;
    }
    uint predictlength = (18*2 + 2*(s.length-firstNonZero)) / 19;
    data = new BigDigit[predictlength];
    uint hi = biguintFromDecimal(data, s[firstNonZero..$]);
    data.length = hi;
    return true;
}

////////////////////////
//
// All of these member functions create a new BigUint.

// return x >> y
BigUint opShr(ulong y)
{
    assert(y>0);
    uint bits = cast(uint)y & BIGDIGITSHIFTMASK;
    if ((y>>LG2BIGDIGITBITS) >= data.length) return BigUint(ZERO);
    uint words = cast(uint)(y >> LG2BIGDIGITBITS);
    if (bits==0) {
        return BigUint(data[words..$]);
    } else {
        uint [] result = new BigDigit[data.length - words];
        multibyteShr(result, data[words..$], bits);
        if (result.length>1 && result[$-1]==0) return BigUint(result[0..$-1]);
        else return BigUint(result);
    }
}

// return x << y
BigUint opShl(ulong y)
{
    assert(y>0);
    if (isZero()) return this;
    uint bits = cast(uint)y & BIGDIGITSHIFTMASK;
    assert ((y>>LG2BIGDIGITBITS) < cast(ulong)(uint.max));
    uint words = cast(uint)(y >> LG2BIGDIGITBITS);
    BigDigit [] result = new BigDigit[data.length + words+1];
    result[0..words] = 0;
    if (bits==0) {
        result[words..words+data.length] = data[];
        return BigUint(result[0..words+data.length]);
    } else {
        uint c = multibyteShl(result[words..words+data.length], data, bits);
        if (c==0) return BigUint(result[0..words+data.length]);
        result[$-1] = c;
        return BigUint(result);
    }
}

// If wantSub is false, return x+y, leaving sign unchanged
// If wantSub is true, return abs(x-y), negating sign if x<y
static BigUint addOrSubInt(BigUint x, ulong y, bool wantSub, bool *sign) {
    BigUint r;
    if (wantSub) { // perform a subtraction
        if (x.data.length > 2) {
            r.data = subInt(x.data, y);                
        } else { // could change sign!
            ulong xx = x.data[0];
            if (x.data.length > 1) xx+= (cast(ulong)x.data[1]) << 32;
            ulong d;
            if (xx <= y) {
                d = y - xx;
                *sign = !*sign;
            } else {
                d = xx - y;
            }
            if (d==0) {
                r = 0;
                return r;
            }
            r.data = new BigDigit[ d > uint.max ? 2: 1];
            r.data[0] = cast(uint)(d & 0xFFFF_FFFF);
            if (d > uint.max) r.data[1] = cast(uint)(d>>32);
        }
    } else {
        r.data = addInt(x.data, y);
    }
    return r;
}

// If wantSub is false, return x + y, leaving sign unchanged.
// If wantSub is true, return abs(x - y), negating sign if x<y
static BigUint addOrSub(BigUint x, BigUint y, bool wantSub, bool *sign) {
    BigUint r;
    if (wantSub) { // perform a subtraction
        r.data = sub(x.data, y.data, sign);
        if (r.isZero()) {
            *sign = false;
        }
    } else {
        r.data = add(x.data, y.data);
    }
    return r;
}


//  return x*y.
//  y must not be zero.
static BigUint mulInt(BigUint x, ulong y)
{
    if (y==0 || x == 0) return BigUint(ZERO);
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y & 0xFFFF_FFFF);
    uint [] result = new BigDigit[x.data.length+1+(hi!=0)];
    result[x.data.length] = multibyteMul(result[0..x.data.length], x.data, lo, 0);
    if (hi!=0) {
        result[x.data.length+1] = multibyteMulAdd!('+')(result[1..x.data.length+1],
            x.data, hi, 0);
    }
    return BigUint(removeLeadingZeros(result));
}

/*  return x*y.
 */
static BigUint mul(BigUint x, BigUint y)
{
    if (y==0 || x == 0) return BigUint(ZERO);

    uint len = x.data.length + y.data.length;
    BigDigit [] result = new BigDigit[len];
    if (y.data.length > x.data.length) {
        mulInternal(result, y.data, x.data);
    } else {
        if (x.data[]==y.data[]) squareInternal(result, x.data);
        else mulInternal(result, x.data, y.data);
    }
    // the highest element could be zero, 
    // in which case we need to reduce the length
    return BigUint(removeLeadingZeros(result));
}

// return x/y
static BigUint divInt(BigUint x, uint y) {
    uint [] result = new BigDigit[x.data.length];
    if ((y&(-y))==y) {
        assert(y!=0, "BigUint division by zero");
        // perfect power of 2
        uint b = 0;
        for (;y!=1; y>>=1) {
            ++b;
        }
        multibyteShr(result, x.data, b);
    } else {
        result[] = x.data[];
        uint rem = multibyteDivAssign(result, y, 0);
    }
    return BigUint(removeLeadingZeros(result));
}

// return x%y
static uint modInt(BigUint x, uint y) {
    assert(y!=0);
    if ((y&(-y))==y) { // perfect power of 2        
        return x.data[0]&(y-1);   
    } else {
        // horribly inefficient - malloc, copy, & store are unnecessary.
        uint [] wasteful = new BigDigit[x.data.length];
        wasteful[] = x.data[];
        uint rem = multibyteDivAssign(wasteful, y, 0);
        delete wasteful;
        return rem;
    }   
}

// return x/y
static BigUint div(BigUint x, BigUint y)
{
    if (y.data.length > x.data.length) return BigUint(ZERO);
    if (y.data.length == 1) return divInt(x, y.data[0]);
    BigDigit [] result = new BigDigit[x.data.length - y.data.length + 1];
    divModInternal(result, null, x.data, y.data);
    return BigUint(removeLeadingZeros(result));
}

// return x%y
static BigUint mod(BigUint x, BigUint y)
{
    if (y.data.length > x.data.length) return x;
    if (y.data.length == 1) {
        BigDigit [] result = new BigDigit[1];
        result[0] = modInt(x, y.data[0]);
        return BigUint(result);
    }
    BigDigit [] result = new BigDigit[x.data.length - y.data.length + 1];
    BigDigit [] rem = new BigDigit[y.data.length];
    divModInternal(result, rem, x.data, y.data);
    return BigUint(removeLeadingZeros(rem));
}

/**
 * Return a BigUint which is x raised to the power of y.
 * Method: Powers of 2 are removed from x, then left-to-right binary
 * exponentiation is used.
 * Memory allocation is minimized: at most one temporary BigUint is used.
 */
static BigUint pow(BigUint x, ulong y)
{
    // Deal with the degenerate cases first.
    if (y==0) return BigUint(ONE);
    if (y==1) return x;
    if (x==0 || x==1) return x;
   
    BigUint result;
     
    // Simplify, step 1: Remove all powers of 2.
    uint firstnonzero = firstNonZeroDigit(x.data);
    
    // See if x can now fit into a single digit.            
    bool singledigit = ((x.data.length - firstnonzero) == 1);
    // If true, then x0 is that digit, and we must calculate x0 ^^ y0.
    BigDigit x0 = x.data[firstnonzero];
    assert(x0 !=0);
    size_t xlength = x.data.length;
    ulong y0;
    uint evenbits = 0; // number of even bits in the bottom of x
    while (!(x0 & 1)) { x0 >>= 1; ++evenbits; }
    
    if ((x.data.length- firstnonzero == 2)) {
        // Check for a single digit straddling a digit boundary
        BigDigit x1 = x.data[firstnonzero+1];
        if ((x1 >> evenbits) == 0) {
            x0 |= (x1 << (BigDigit.sizeof * 8 - evenbits));
            singledigit = true;
        }
    }
    uint evenshiftbits = 0; // Total powers of 2 to shift by, at the end
    
    // Simplify, step 2: For singledigits, see if we can trivially reduce y
    
    BigDigit finalMultiplier = 1;
   
    if (singledigit) {
        // x fits into a single digit. Raise it to the highest power we can
        // that still fits into a single digit, then reduce the exponent accordingly.
        // We're quite likely to have a residual multiply at the end.
        // For example, 10^^100 = (((5^^13)^^7) * 5^^9) * 2^^100.
        // and 5^^13 still fits into a uint.
        evenshiftbits  = cast(uint)( (evenbits * y) & BIGDIGITSHIFTMASK);
        if (x0 == 1) { // Perfect power of 2
             result = 1;
             return result<< (evenbits + firstnonzero*BigDigit.sizeof)*y;
        } else {
            int p = highestPowerBelowUintMax(x0);
            if (y <= p) { // Just do it with pow               
                result = intpow(x0, y);
                if (evenshiftbits+firstnonzero == 0) return result;
                return result<< (evenbits + firstnonzero*BigDigit.sizeof)*y;
            }
            y0 = y/p;
            finalMultiplier = intpow(x0, y - y0*p);
            x0 = intpow(x0, p);
        }
        xlength = 1;
    }

    // Check for overflow and allocate result buffer
    // Single digit case: +1 is for final multiplier, + 1 is for spare evenbits.
    ulong estimatelength = singledigit ? firstnonzero*y + y0*1 + 2 + ((evenbits*y) >> LG2BIGDIGITBITS) 
        : x.data.length * y; // estimated length in BigDigits
    // (Estimated length can overestimate by a factor of 2, if x.data.length ~ 2).
    if (estimatelength > uint.max/(4*BigDigit.sizeof)) assert(0, "Overflow in BigInt.pow");
    
    // The result buffer includes space for all the trailing zeros
    BigDigit [] resultBuffer = new BigDigit[cast(size_t)estimatelength];
    
    // Do all the powers of 2!
    size_t result_start = cast(size_t)(firstnonzero*y + singledigit? ((evenbits*y) >> LG2BIGDIGITBITS) : 0);
    resultBuffer[0..result_start] = 0;
    BigDigit [] t1 = resultBuffer[result_start..$];
    BigDigit [] r1;
    
    if (singledigit) {
        r1 = t1[0..1];
        r1[0] = x0;
        y = y0;        
    } else {
        // It's not worth right shifting by evenbits unless we also shrink the length after each 
        // multiply or squaring operation. That might still be worthwhile for large y.
        r1 = t1[0..x.data.length - firstnonzero];
        r1[0..$] = x.data[firstnonzero..$];
    }    

    if (y>1) {    // Set r1 = r1 ^^ y.
         
        // The secondary buffer only needs space for the multiplication results    
        BigDigit [] secondaryBuffer = new BigDigit[resultBuffer.length - result_start];
        BigDigit [] t2 = secondaryBuffer;
        BigDigit [] r2;
    
        int shifts = 63; // num bits in a long
        while(!(y & 0x8000_0000_0000_0000L)) {
            y <<= 1;
            --shifts;
        }
        y <<=1;
   
        while(y!=0) {
            r2 = t2[0 .. r1.length*2];
            squareInternal(r2, r1);
            if (y & 0x8000_0000_0000_0000L) {           
                r1 = t1[0 .. r2.length + xlength];
                if (xlength == 1) {
                    r1[$-1] = multibyteMul(r1[0 .. $-1], r2, x0, 0);
                } else {
                    mulInternal(r1, r2, x.data);
                }
            } else {
                r1 = t1[0 .. r2.length];
                r1[] = r2[];
            }
            y <<=1;
            shifts--;
        }
        while (shifts>0) {
            r2 = t2[0 .. r1.length * 2];
            squareInternal(r2, r1);
            r1 = t1[0 .. r2.length];
            r1[] = r2[];
            --shifts;
        }
    }   

    if (finalMultiplier!=1) {
        BigDigit carry = multibyteMul(r1, r1, finalMultiplier, 0);
        if (carry) {
            r1 = t1[0 .. r1.length + 1];
            r1[$-1] = carry;
        }
    }
    if (evenshiftbits) {
        BigDigit carry = multibyteShl(r1, r1, evenshiftbits);
        if (carry!=0) {
            r1 = t1[0 .. r1.length + 1];
            r1[$ - 1] = carry;
        }
    }    
    while(r1[$ - 1]==0) {
        r1=r1[0 .. $ - 1];
    }
    result.data = resultBuffer[0 .. result_start + r1.length];
    return result;
}

} // end BigUint


// Remove leading zeros from x, to restore the BigUint invariant
BigDigit[] removeLeadingZeros(BigDigit [] x)
{
    size_t k = x.length;
    while(k>1 && x[k - 1]==0) --k;
    return x[0 .. k];
}

debug(UnitTest) {
unittest {
// Bug 1650.
   BigUint r = BigUint([5]);
   BigUint t = BigUint([7]);
   BigUint s = BigUint.mod(r, t);
   assert(s==5);
}
}



debug (UnitTest) {
// Pow tests
unittest {
    BigUint r, s;
    r.fromHexString("80000000_00000001".dup);
    s = BigUint.pow(r, 5);
    r.fromHexString("08000000_00000000_50000000_00000001_40000000_00000002_80000000".dup
      ~ "_00000002_80000000_00000001".dup);
    assert(s == r);
    s = 10;
    s = BigUint.pow(s, 39);
    r.fromDecimalString("1000000000000000000000000000000000000000".dup);
    assert(s == r);
    r.fromHexString("1_E1178E81_00000000".dup);
    s = BigUint.pow(r, 15); // Regression test: this used to overflow array bounds

}

// Radix conversion tests
unittest {   
    BigUint r;
    r.fromHexString("1_E1178E81_00000000".dup);
    assert(r.toHexString(0, '_', 0) == "1_E1178E81_00000000");
    assert(r.toHexString(0, '_', 20) == "0001_E1178E81_00000000");
    assert(r.toHexString(0, '_', 16+8) == "00000001_E1178E81_00000000");
    assert(r.toHexString(0, '_', 16+9) == "0_00000001_E1178E81_00000000");
    assert(r.toHexString(0, '_', 16+8+8) ==   "00000000_00000001_E1178E81_00000000");
    assert(r.toHexString(0, '_', 16+8+8+1) ==      "0_00000000_00000001_E1178E81_00000000");
    assert(r.toHexString(0, '_', 16+8+8+1, ' ') == "                  1_E1178E81_00000000");
    assert(r.toHexString(0, 0, 16+8+8+1) == "00000000000000001E1178E8100000000");
    r = 0;
    assert(r.toHexString(0, '_', 0) == "0");
    assert(r.toHexString(0, '_', 7) == "0000000");
    assert(r.toHexString(0, '_', 7, ' ') == "      0");
    assert(r.toHexString(0, '#', 9) == "0#00000000");
    assert(r.toHexString(0, 0, 9) == "000000000");
    
}
}

private:

// works for any type
T intpow(T)(T x, ulong n)
{
    T p;

    switch (n)
    {
    case 0:
        p = 1;
        break;

    case 1:
        p = x;
        break;

    case 2:
        p = x * x;
        break;

    default:
        p = 1;
        while (1){
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


//  returns the maximum power of x that will fit in a uint.
int highestPowerBelowUintMax(uint x)
{
     assert(x>1);     
     const ubyte [22] maxpwr = [31, 20, 15, 13, 12, 11, 10, 10, 9, 9,
                                 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 7, 7];
     if (x<24) return maxpwr[x-2]; 
     if (x<41) return 6;
     if (x<85) return 5;
     if (x<256) return 4;
     if (x<1626) return 3;
     if (x<65536) return 2;
     return 1;
}

//  returns the maximum power of x that will fit in a ulong.
int highestPowerBelowUlongMax(uint x)
{
     assert(x>1);     
     const ubyte [39] maxpwr = [63, 40, 31, 27, 24, 22, 21, 20, 19, 18,
                                 17, 17, 16, 16, 15, 15, 15, 15, 14, 14,
                                 14, 14, 13, 13, 13, 13, 13, 13, 13, 12,
                                 12, 12, 12, 12, 12, 12, 12, 12, 12];
     if (x<41) return maxpwr[x-2]; 
     if (x<57) return 11;
     if (x<85) return 10;
     if (x<139) return 9;
     if (x<256) return 8;
     if (x<566) return 7;
     if (x<1626) return 6;
     if (x<7132) return 5;
     if (x<65536) return 4;
     if (x<2642246) return 3;
     return 2;
} 

version(UnitTest) {
int slowHighestPowerBelowUintMax(uint x)
{
     int pwr = 1;
     for (ulong q = x;x*q < cast(ulong)uint.max; ) {
         q*=x; ++pwr;
     } 
     return pwr;
}

unittest {
  assert(highestPowerBelowUintMax(10)==9);
  for (int k=82; k<88; ++k) {assert(highestPowerBelowUintMax(k)== slowHighestPowerBelowUintMax(k)); }
}
}


/*  General unsigned subtraction routine for bigints.
 *  Sets result = x - y. If the result is negative, negative will be true.
 */
BigDigit [] sub(in BigDigit[] x, in BigDigit[] y, bool *negative)
{
    if (x.length == y.length) {
        // There's a possibility of cancellation, if x and y are almost equal.
        int last = highestDifferentDigit(x, y);
        BigDigit [] result = new BigDigit[last+1];
        if (x[last] < y[last]) { // we know result is negative
            multibyteSub(result[0..last+1], y[0..last+1], x[0..last+1], 0);
            *negative = true;
        } else { // positive or zero result
            multibyteSub(result[0..last+1], x[0..last+1], y[0..last+1], 0);
            *negative = false;
        }
        while (result.length > 1 && result[$-1] == 0) {
            result = result[0..$-1];
        }
        return result;
    }
    // Lengths are different
    const (BigDigit) [] large, small;
    if (x.length < y.length) {
        *negative = true;
        large = y; small = x;
    } else {
        *negative = false;
        large = x; small = y;
    }
    
    BigDigit [] result = new BigDigit[large.length];
    BigDigit carry = multibyteSub(result[0..small.length], large[0..small.length], small, 0);
    result[small.length..$] = large[small.length..$];
    if (carry) {
        multibyteIncrementAssign!('-')(result[small.length..$], carry);
    }
    while (result.length > 1 && result[$-1] == 0) {
        result = result[0..$-1];
    }    
    return result;
}


// return a + b
BigDigit [] add(BigDigit[] a, BigDigit [] b) {
    BigDigit [] x, y;
    if (a.length<b.length) { x = b; y = a; } else { x = a; y = b; }
    // now we know x.length > y.length
    // create result. add 1 in case it overflows
    BigDigit [] result = new BigDigit[x.length + 1];
    
    BigDigit carry = multibyteAdd(result[0..y.length], x[0..y.length], y, 0);
    if (x.length != y.length){
        result[y.length..$-1]= x[y.length..$];
        carry  = multibyteIncrementAssign!('+')(result[y.length..$-1], carry);
    }
    if (carry) {
        result[$-1] = carry;
        return result;
    } else return result[0..$-1];
}
    
/**  return x + y
 */
BigDigit [] addInt(BigDigit[] x, ulong y)
{
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y& 0xFFFF_FFFF);
    uint len = x.length;
    if (x.length < 2 && hi!=0) ++len;
    BigDigit [] result = new BigDigit[len+1];
    result[0..x.length] = x[]; 
    if (x.length < 2 && hi!=0) { result[1]=hi; hi=0; }	
    uint carry = multibyteIncrementAssign!('+')(result[0..$-1], lo);
    if (hi!=0) carry += multibyteIncrementAssign!('+')(result[1..$-1], hi);
    if (carry) {
        result[$-1] = carry;
        return result;
    } else return result[0..$-1];
}

/** Return x - y.
 *  x must be greater than y.
 */  
BigDigit [] subInt(BigDigit[] x, ulong y)
{
    uint hi = cast(uint)(y >>> 32);
    uint lo = cast(uint)(y & 0xFFFF_FFFF);
    BigDigit [] result = new BigDigit[x.length];
    result[] = x[];
    multibyteIncrementAssign!('-')(result[], lo);
    if (hi) multibyteIncrementAssign!('-')(result[1..$], hi);
    if (result[$-1]==0) return result[0..$-1];
    else return result; 
}

/**  General unsigned multiply routine for bigints.
 *  Sets result = x * y.
 *
 *  The length of y must not be larger than the length of x.
 *  Different algorithms are used, depending on the lengths of x and y.
 *  TODO: "Modern Computer Arithmetic" suggests the OddEvenKaratsuba algorithm for the
 *  unbalanced case. (But I doubt it would be faster in practice).
 *  
 */
void mulInternal(BigDigit[] result, in BigDigit[] x, in BigDigit[] y)
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
            BigDigit [KARATSUBALIMIT] partial;
            partial[0..y.length] = result[done..done+y.length];
            mulSimple(result[done..done+chunksize+y.length], x[done..done+chunksize], y);
            addAssignSimple(result[done..done+chunksize + y.length], partial[0..y.length]);
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
        BigDigit [] scratchbuff = new BigDigit[karatsubaRequiredBuffSize(maxchunk) + y.length];
        BigDigit [] partial = scratchbuff[$ - y.length .. $];
        uint done; // how much of X have we done so far?
        double residual = 0;
        if (paddingY) {
            // If the first chunk is bigger, do it first. We're padding y. 
          mulKaratsuba(result[0 .. y.length + chunksize + (extra > 0 ? 1 : 0 )], 
                        x[0 .. chunksize + (extra>0?1:0)], y, scratchbuff);
          done = chunksize + (extra > 0 ? 1 : 0);
          if (extra) --extra;
        } else { // We're padding X. Begin with the extra bit.
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
            addAssignSimple(result[done .. done + y.length + chunksize], partial);
            done += chunksize;
        }
        delete scratchbuff;
    } else {
        // Balanced. Use Karatsuba directly.
        BigDigit [] scratchbuff = new BigDigit[karatsubaRequiredBuffSize(x.length)];
        mulKaratsuba(result, x, y, scratchbuff);
        delete scratchbuff;
    }
}

/**  General unsigned squaring routine for BigInts.
 *   Sets result = x*x.
 *   NOTE: If the highest half-digit of x is zero, the highest digit of result will
 *   also be zero.
 */
void squareInternal(BigDigit[] result, BigDigit[] x)
{
  // TODO: Squaring is potentially half a multiply, plus add the squares of 
  // the diagonal elements.
  assert(result.length == 2*x.length);
  if (x.length <= KARATSUBASQUARELIMIT) {
      if (x.length==1) {
         result[1] = multibyteMul(result[0..1], x, x[0], 0);
         return;
      }
      return squareSimple(result, x);
  }
  // The nice thing about squaring is that it always stays balanced
  BigDigit [] scratchbuff = new BigDigit[karatsubaRequiredBuffSize(x.length)];
  squareKaratsuba(result, x, scratchbuff);
  delete scratchbuff;  
}


import tango.core.BitManip : bsr;

/// if remainder is null, only calculate quotient.
void divModInternal(BigDigit [] quotient, BigDigit[] remainder, BigDigit [] u, BigDigit [] v)
{
    assert(quotient.length == u.length - v.length + 1);
    assert(remainder==null || remainder.length == v.length);
    assert(v.length > 1);
    assert(u.length >= v.length);
    
    // Normalize by shifting v left just enough so that
    // its high-order bit is on, and shift u left the
    // same amount. The highest bit of u will never be set.
   
    BigDigit [] vn = new BigDigit[v.length];
    BigDigit [] un = new BigDigit[u.length + 1];
    // How much to left shift v, so that its MSB is set.
    uint s = BIGDIGITSHIFTMASK - bsr(v[$-1]);
    if (s!=0) {
        multibyteShl(vn, v, s);        
        un[$-1] = multibyteShl(un[0..$-1], u, s);
    } else {
        vn[] = v[];
        un[0..$-1] = u[];
        un[$-1] = 0;
    }
    if (quotient.length<FASTDIVLIMIT) {
        schoolbookDivMod(quotient, un, vn);
    } else {
        fastDivMod(quotient, un, vn);        
    }
    
    // Unnormalize remainder, if required.
    if (remainder != null) {
        if (s == 0) remainder[] = un[0..vn.length];
        else multibyteShr(remainder, un[0..vn.length+1], s);
    }
    delete un;
    delete vn;
}

debug(UnitTest)
{
unittest {
    uint [] u = [0, 0xFFFF_FFFE, 0x8000_0000];
    uint [] v = [0xFFFF_FFFF, 0x8000_0000];
    uint [] q = new uint[u.length - v.length + 1];
    uint [] r = new uint[2];
    divModInternal(q, r, u, v);
    assert(q[]==[0xFFFF_FFFFu, 0]);
    assert(r[]==[0xFFFF_FFFFu, 0x7FFF_FFFF]);
    u = [0, 0xFFFF_FFFE, 0x8000_0001];
    v = [0xFFFF_FFFF, 0x8000_0000];
    divModInternal(q, r, u, v);
}
}

private:
// Converts a big uint to a hexadecimal string.
//
// Optionally, a separator character (eg, an underscore) may be added between
// every 8 digits.
// buff.length must be data.length*8 if separator is zero,
// or data.length*9 if separator is non-zero. It will be completely filled.
char [] biguintToHex(char [] buff, BigDigit [] data, char separator=0)
{
    int x=0;
    for (int i=data.length - 1; i>=0; --i) {
        toHexZeroPadded(buff[x..x+8], data[i]);
        x+=8;
        if (separator) {
            if (i>0) buff[x] = separator;
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
 *          Will be filled backwards, starting from buff[$-1].
 *
 * buff.length must be >= (data.length*32)/log2(10) = 9.63296 * data.length.
 * Returns:
 *    the lowest index of buff which was used.
 */
int biguintToDecimal(char [] buff, BigDigit [] data){
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
    sofar -= 10;
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
int biguintFromDecimal(BigDigit [] data, const(char []) s) {
    // Convert to base 1e19 = 10_000_000_000_000_000_000.
    // (this is the largest power of 10 that will fit into a long).
    // The length will be less than 1 + s.length/log2(10) = 1 + s.length/3.3219.
    // 485 bits will only just fit into 146 decimal digits.
    uint lo = 0;
    uint x = 0;
    ulong y = 0;
    uint hi = 0;
    data[0] = 0; // initially number is 0.
    data[1] = 0;    
   
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
    if (lo!=0) {
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
void mulSimple(BigDigit[] result, in BigDigit [] left, in BigDigit[] right)
in {    
    assert(result.length == left.length + right.length);
    assert(right.length>1);
}
body {
    result[left.length] = multibyteMul(result[0..left.length], left, right[0], 0);   
    multibyteMultiplyAccumulate(result[1..$], left, right[1..$]);
}

// Classic 'schoolbook' squaring
void squareSimple(BigDigit[] result, BigDigit [] x)
in {    
    assert(result.length == 2*x.length);
    assert(x.length>1);
}
body {
    multibyteSquare(result, x);
}


// add two uints of possibly different lengths. Result must be as long
// as the larger length.
// Returns carry (0 or 1).
uint addSimple(BigDigit [] result, BigDigit [] left, BigDigit [] right)
in {
    assert(result.length == left.length);
    assert(left.length >= right.length);
    assert(right.length>0);
}
body {
    uint carry = multibyteAdd(result[0..right.length],
            left[0..right.length], right, 0);
    if (right.length < left.length) {
        result[right.length..left.length] = left[right.length .. $];            
        carry = multibyteIncrementAssign!('+')(result[right.length..$], carry);
    }
    return carry;
}

//  result = left - right
// returns carry (0 or 1)
BigDigit subSimple(BigDigit [] result, BigDigit [] left, BigDigit [] right)
in {
    assert(result.length == left.length);
    assert(left.length >= right.length);
    assert(right.length>0);
}
body {
    BigDigit carry = multibyteSub(result[0..right.length],
            left[0..right.length], right, 0);
    if (right.length < left.length) {
        result[right.length..left.length] = left[right.length .. $];            
        carry = multibyteIncrementAssign!('-')(result[right.length..$], carry);
    } //else if (result.length==left.length+1) { result[$-1] = carry; carry=0; }
    return carry;
}


/* result = result - right 
 * Returns carry = 1 if result was less than right.
*/
BigDigit subAssignSimple(BigDigit [] result, BigDigit [] right)
{
    assert(result.length >= right.length);
    uint c = multibyteSub(result[0..right.length], result[0..right.length], right, 0); 
    if (c && result.length > right.length) c = multibyteIncrementAssign!('-')(result[right.length .. $], c);
    return c;
}

/* result = result + right
*/
BigDigit addAssignSimple(BigDigit [] result, BigDigit [] right)
{
    assert(result.length >= right.length);
    uint c = multibyteAdd(result[0..right.length], result[0..right.length], right, 0);
    if (c && result.length > right.length) {
       c = multibyteIncrementAssign!('+')(result[right.length .. $], c);
    }
    return c;
}

/* performs result += wantSub? - right : right;
*/
BigDigit addOrSubAssignSimple(BigDigit [] result, BigDigit [] right, bool wantSub)
{
  if (wantSub) return subAssignSimple(result, right);
  else return addAssignSimple(result, right);
}


// return true if x<y, considering leading zeros
bool less(in BigDigit[] x, in BigDigit[] y)
{
    assert(x.length >= y.length);
    uint k = x.length-1;
    while(x[k]==0 && k>=y.length) --k; 
    if (k>=y.length) return false;
    while (k>0 && x[k]==y[k]) --k;
    return x[k] < y[k];
}

// Set result = abs(x-y), return true if result is negative(x<y), false if x<=y.
bool inplaceSub(BigDigit[] result, in BigDigit[] x, in BigDigit[] y)
{
    assert(result.length == (x.length >= y.length) ? x.length : y.length);
    
    size_t minlen;
    bool negative;
    if (x.length >= y.length) {
        minlen = y.length;
        negative = less(x, y);
    } else {
       minlen = x.length;
       negative = !less(y, x);
    }
    const(BigDigit)[] large, small;
    if (negative) { large = y; small=x; } else { large=x; small=y; }
       
    BigDigit carry = multibyteSub(result[0..minlen], large[0..minlen], small[0..minlen], 0);
    if (x.length != y.length) {
        result[minlen..large.length]= large[minlen..$];
        result[large.length..$] = 0;
        if (carry) multibyteIncrementAssign!('-')(result[minlen..$], carry);
    }
    return negative;
}

/* Determine how much space is required for the temporaries
 * when performing a Karatsuba multiplication. 
 */
uint karatsubaRequiredBuffSize(uint xlen)
{
    return xlen <= KARATSUBALIMIT ? 0 : 2*xlen; // - KARATSUBALIMIT+2;
}

/* Sets result = x*y, using Karatsuba multiplication.
* x must be longer or equal to y.
* Valid only for balanced multiplies, where x is not shorter than y.
* It is superior to schoolbook multiplication if and only if 
*    sqrt(2)*y.length > x.length > y.length.
* Karatsuba multiplication is O(n^1.59), whereas schoolbook is O(n^2)
* The maximum allowable length of x and y is uint.max; but better algorithms
* should be used far before that length is reached.
* Params:
* scratchbuff      An array long enough to store all the temporaries. Will be destroyed.
*/
void mulKaratsuba(BigDigit [] result, in BigDigit [] x, in BigDigit[] y, BigDigit [] scratchbuff)
{
    assert(x.length >= y.length);
	  assert(result.length < uint.max, "Operands too large");
    assert(result.length == x.length + y.length);
    if (x.length <= KARATSUBALIMIT) {
        return mulSimple(result, x, y);
    }
    // Must be almost square (otherwise, a schoolbook iteration is better)
    assert(2L * y.length * y.length > (x.length-1) * (x.length-1),
        "Bigint Internal Error: Asymmetric Karatsuba");
        
    // The subtractive version of Karatsuba multiply uses the following result:
    // (Nx1 + x0)*(Ny1 + y0) = (N*N)*x1y1 + x0y0 + N * (x0y0 + x1y1 - mid)
    // where mid = (x0-x1)*(y0-y1)
    // requiring 3 multiplies of length N, instead of 4.
    // The advantage of the subtractive over the additive version is that
    // the mid multiply cannot exceed length N. But there are subtleties:
    // (x0-x1),(y0-y1) may be negative or zero. To keep it simple, we 
    // retain all of the leading zeros in the subtractions
    
    // half length, round up.
    uint half = (x.length >> 1) + (x.length & 1);
    
    const(BigDigit) [] x0 = x[0 .. half];
    const(BigDigit) [] x1 = x[half .. $];    
    const(BigDigit) [] y0 = y[0 .. half];
    const(BigDigit) [] y1 = y[half .. $];
    BigDigit [] mid = scratchbuff[0 .. half*2];
    BigDigit [] newscratchbuff = scratchbuff[half*2 .. $];
    BigDigit [] resultLow = result[0 .. 2*half];
    BigDigit [] resultHigh = result[2*half .. $];
     // initially use result to store temporaries
    BigDigit [] xdiff= result[0 .. half];
    BigDigit [] ydiff = result[half .. half*2];
    
    // First, we calculate mid, and sign of mid
    bool midNegative = inplaceSub(xdiff, x0, x1)
                      ^ inplaceSub(ydiff, y0, y1);
    mulKaratsuba(mid, xdiff, ydiff, newscratchbuff);
    
    // Low half of result gets x0 * y0. High half gets x1 * y1
  
    mulKaratsuba(resultLow, x0, y0, newscratchbuff);
    
    if (2L * y1.length * y1.length < x1.length * x1.length) {
        // an asymmetric situation has been created.
        // Worst case is if x:y = 1.414 : 1, then x1:y1 = 2.41 : 1.
        // Applying one schoolbook multiply gives us two pieces each 1.2:1
        if (y1.length <= KARATSUBALIMIT) {
            mulSimple(resultHigh, x1, y1);
        } else {
            // divide x1 in two, then use schoolbook multiply on the two pieces.
            uint quarter = (x1.length >> 1) + (x1.length & 1);
            bool ysmaller = (quarter >= y1.length);
            mulKaratsuba(resultHigh[0..quarter+y1.length], ysmaller ? x1[0..quarter] : y1, 
                ysmaller ? y1 : x1[0..quarter], newscratchbuff);
            // Save the part which will be overwritten.
            bool ysmaller2 = ((x1.length - quarter) >= y1.length);
            newscratchbuff[0..y1.length] = resultHigh[quarter..quarter + y1.length];
            mulKaratsuba(resultHigh[quarter..$], ysmaller2 ? x1[quarter..$] : y1, 
                ysmaller2 ? y1 : x1[quarter..$], newscratchbuff[y1.length..$]);

            resultHigh[quarter..$].addAssignSimple(newscratchbuff[0..y1.length]);                
        }
    } else mulKaratsuba(resultHigh, x1, y1, newscratchbuff);

    /* We now have result = x0y0 + (N*N)*x1y1
       Before adding or subtracting mid, we must calculate
       result += N * (x0y0 + x1y1)    
       We can do this with three half-length additions. With a = x0y0, b = x1y1:
                      aHI aLO
        +       aHI   aLO
        +       bHI   bLO
        +  bHI  bLO
        =  R3   R2    R1   R0        
        R1 = aHI + bLO + aLO
        R2 = aHI + bLO + aHI + carry_from_R1
        R3 = bHi + carry_from_R2
         Can also do use newscratchbuff:

//    It might actually be quicker to do it in two full-length additions:        
//    newscratchbuff[2*half] = addSimple(newscratchbuff[0..2*half], result[0..2*half], result[2*half..$]);
//    addAssignSimple(result[half..$], newscratchbuff[0..2*half+1]);
   */
    BigDigit[] R1 = result[half..half*2];
    BigDigit[] R2 = result[half*2..half*3];
    BigDigit[] R3 = result[half*3..$];
    BigDigit c1 = multibyteAdd(R2, R2, R1, 0); // c1:R2 = R2 + R1
    BigDigit c2 = multibyteAdd(R1, R2, result[0..half], 0); // c2:R1 = R2 + R1 + R0
    BigDigit c3 = addAssignSimple(R2, R3); // R2 = R2 + R1 + R3
    if (c1+c2) multibyteIncrementAssign!('+')(result[half*2..$], c1+c2);
    if (c1+c3) multibyteIncrementAssign!('+')(R3, c1+c3);
     
    // And finally we subtract mid
    addOrSubAssignSimple(result[half..$], mid, !midNegative);
}

void squareKaratsuba(BigDigit [] result, BigDigit [] x, BigDigit [] scratchbuff)
{
    // See mulKaratsuba for implementation comments.
    // Squaring is simpler, since it never gets asymmetric.
	  assert(result.length < uint.max, "Operands too large");
    assert(result.length == 2*x.length);
    if (x.length <= KARATSUBASQUARELIMIT) {
        return squareSimple(result, x);
    }
    // half length, round up.
    uint half = (x.length >> 1) + (x.length & 1);
    
    BigDigit [] x0 = x[0 .. half];
    BigDigit [] x1 = x[half .. $];    
    BigDigit [] mid = scratchbuff[0 .. half*2];
    BigDigit [] newscratchbuff = scratchbuff[half*2 .. $];
     // initially use result to store temporaries
    BigDigit [] xdiff= result[0 .. half];
    BigDigit [] ydiff = result[half .. half*2];
    
    // First, we calculate mid. We don't need its sign
    inplaceSub(xdiff, x0, x1);
    squareKaratsuba(mid, xdiff, newscratchbuff);
  
    // Set result = x0x0 + (N*N)*x1x1
    squareKaratsuba(result[0 .. 2*half], x0, newscratchbuff);
    squareKaratsuba(result[2*half .. $], x1, newscratchbuff);

    /* result += N * (x0x0 + x1x1)    
       Do this with three half-length additions. With a = x0x0, b = x1x1:
        R1 = aHI + bLO + aLO
        R2 = aHI + bLO + aHI + carry_from_R1
        R3 = bHi + carry_from_R2
    */
    BigDigit[] R1 = result[half..half*2];
    BigDigit[] R2 = result[half*2..half*3];
    BigDigit[] R3 = result[half*3..$];
    BigDigit c1 = multibyteAdd(R2, R2, R1, 0); // c1:R2 = R2 + R1
    BigDigit c2 = multibyteAdd(R1, R2, result[0..half], 0); // c2:R1 = R2 + R1 + R0
    BigDigit c3 = addAssignSimple(R2, R3); // R2 = R2 + R1 + R3
    if (c1+c2) multibyteIncrementAssign!('+')(result[half*2..$], c1+c2);
    if (c1+c3) multibyteIncrementAssign!('+')(R3, c1+c3);
     
    // And finally we subtract mid, which is always positive
    subAssignSimple(result[half..$], mid);
}

/* Knuth's Algorithm D, as presented in 
 * H.S. Warren, "Hacker's Delight", Addison-Wesley Professional (2002).
 * Also described in "Modern Computer Arithmetic" 0.2, Exercise 1.8.18.
 * Given u and v, calculates  quotient  = u/v, u = u%v.
 * v must be normalized (ie, the MSB of v must be 1).
 * The most significant words of quotient and u may be zero.
 * u[0..v.length] holds the remainder.
 */
void schoolbookDivMod(BigDigit [] quotient, BigDigit [] u, in BigDigit [] v)
{
    assert(quotient.length == u.length - v.length);
    assert(v.length > 1);
    assert(u.length >= v.length);
    assert((v[$-1]&0x8000_0000)!=0);
    assert(u[$-1] < v[$-1]);
    // BUG: This code only works if BigDigit is uint.
    uint vhi = v[$-1];
    uint vlo = v[$-2];
        
    for (int j = u.length - v.length - 1; j >= 0; j--) {
        // Compute estimate of quotient[j],
        // qhat = (three most significant words of u)/(two most sig words of v).
        uint qhat;               
        if (u[j + v.length] == vhi) {
            // uu/vhi could exceed uint.max (it will be 0x8000_0000 or 0x8000_0001)
            qhat = uint.max;
        } else {
            uint ulo = u[j + v.length - 2];
version(Naked_D_InlineAsm_X86) {
            // Note: On DMD, this is only ~10% faster than the non-asm code. 
            uint *p = &u[j + v.length - 1];
            asm {
                mov EAX, p;
                mov EDX, [EAX+4];
                mov EAX, [EAX];
                div dword ptr [vhi];
                mov qhat, EAX;
                mov ECX, EDX;
div3by2correction:                
                mul dword ptr [vlo]; // EDX:EAX = qhat * vlo
                sub EAX, ulo;
                sbb EDX, ECX;
                jbe div3by2done;
                mov EAX, qhat;
                dec EAX;
                mov qhat, EAX;
                add ECX, dword ptr [vhi];
                jnc div3by2correction;
div3by2done:    ;
}
            } else { // version(InlineAsm)
                ulong uu = (cast(ulong)(u[j+v.length]) << 32) | u[j+v.length-1];
                ulong bigqhat = uu / vhi;
                ulong rhat =  uu - bigqhat * vhi;
                qhat = cast(uint)bigqhat;            
       again:
                if (cast(ulong)qhat*vlo > ((rhat<<32) + ulo)) {
                    --qhat;
                    rhat += vhi;
                    if (!(rhat & 0xFFFF_FFFF_0000_0000L)) goto again;
                }
            } // version(InlineAsm)
        } 
        // Multiply and subtract.
        uint carry = multibyteMulAdd!('-')(u[j..j+v.length], v, qhat, 0);

        if (u[j+v.length] < carry) {
            // If we subtracted too much, add back
            --qhat;
            carry -= multibyteAdd(u[j..j+v.length],u[j..j+v.length], v, 0);
        }
        quotient[j] = qhat;
        u[j + v.length] = u[j + v.length] - carry;
    }
}

private:
// TODO: Replace with a library call
void itoaZeroPadded(char[] output, uint value, int radix = 10) {
    int x = output.length - 1;
    for( ; x>=0; --x) {
        output[x]= cast(char)(value % radix + '0');
        value /= radix;
    }
}

void toHexZeroPadded(char[] output, uint value) {
    int x = output.length - 1;
    const char [] hexDigits = "0123456789ABCDEF";
    for( ; x>=0; --x) {        
        output[x] = hexDigits[value & 0xF];
        value >>= 4;
    }
}

private:
    
// Returns the highest value of i for which left[i]!=right[i],
// or 0 if left[]==right[]
int highestDifferentDigit(in BigDigit [] left, in BigDigit [] right)
{
    assert(left.length == right.length);
    for (int i=left.length-1; i>0; --i) {
        if (left[i]!=right[i]) return i;
    }
    return 0;
}

// Returns the lowest value of i for which x[i]!=0.
int firstNonZeroDigit(BigDigit[] x)
{
    int k = 0;
    while (x[k]==0) {
        ++k;
        assert(k<x.length);
    }
    return k;
}

/* Calculate quotient and remainder of u / v using fast recursive division.
  v must be normalised, and must be at least half as long as u.
  Given u and v, v normalised, calculates  quotient  = u/v, u = u%v.
  Algorithm is described in 
  - C. Burkinel and J. Ziegler, "Fast Recursive Division", MPI-I-98-1-022, 
    Max-Planck Institute fuer Informatik, (Oct 1998).
  - R.P. Brent and P. Zimmermann, "Modern Computer Arithmetic", 
    Version 0.2, p. 26, (June 2008).
Returns:    
    u[0..v.length] is the remainder. u[v.length..$] is corrupted.
    scratch is temporary storage space, must be at least as long as quotient.
*/
void recursiveDivMod(BigDigit[] quotient, BigDigit[] u, in BigDigit[] v,
                     BigDigit[] scratch)
in {
    assert(quotient.length == u.length - v.length);
    assert(u.length <= 2 * v.length, "Asymmetric division"); // use base-case division to get it to this situation
    assert(v.length > 1);
    assert(u.length >= v.length);
    assert((v[$ - 1] & 0x8000_0000) != 0);
    assert(scratch.length >= quotient.length);
    
}
body {
    if(quotient.length < FASTDIVLIMIT) {
        return schoolbookDivMod(quotient, u, v);
    }
    uint k = quotient.length >> 1;
    uint h = k + v.length;

    recursiveDivMod(quotient[k .. $], u[2 * k .. $], v[k .. $], scratch);
    adjustRemainder(quotient[k .. $], u[k .. h], v, k,
            scratch[0 .. quotient.length]);
    recursiveDivMod(quotient[0 .. k], u[k .. h], v[k .. $], scratch);
    adjustRemainder(quotient[0 .. k], u[0 .. v.length], v, k,
            scratch[0 .. 2 * k]);
}

// rem -= quot * v[0..k].
// If would make rem negative, decrease quot until rem is >=0.
// Needs (quot.length * k) scratch space to store the result of the multiply. 
void adjustRemainder(BigDigit[] quot, BigDigit[] rem, in BigDigit[] v, int k,
                     BigDigit[] scratch)
{
    assert(rem.length == v.length);
    mulInternal(scratch, quot, v[0 .. k]);
    uint carry = subAssignSimple(rem, scratch);
    while(carry) {
        multibyteIncrementAssign!('-')(quot, 1); // quot--
        carry -= multibyteAdd(rem, rem, v, 0);
    }
}

// Cope with unbalanced division by performing block schoolbook division.
void fastDivMod(BigDigit [] quotient, BigDigit [] u, in BigDigit [] v)
{
    assert(quotient.length == u.length - v.length);
    assert(v.length > 1);
    assert(u.length >= v.length);
    assert((v[$-1] & 0x8000_0000)!=0);
    BigDigit [] scratch = new BigDigit[v.length];

    // Perform block schoolbook division, with 'v.length' blocks.
    uint m = u.length - v.length;
    while (m > v.length) {
        recursiveDivMod(quotient[m-v.length..m], 
            u[m - v.length..m + v.length], v, scratch);
        m -= v.length;
    }
    recursiveDivMod(quotient[0..m], u[0..m + v.length], v, scratch);
    delete scratch;
}

debug(UnitTest)
{
import tango.stdc.stdio;

void printBiguint(uint [] data)
{
    char [] buff = new char[data.length*9];
    printf("%.*s\n", biguintToHex(buff, data, '_'));
}

void printDecimalBigUint(BigUint data)
{
   printf("%.*s\n", data.toDecimalString(0)); 
}

unittest{
  uint [] a, b;
  a = new uint[43];
  b = new uint[179];
  for (int i=0; i<a.length; ++i) a[i] = 0x1234_B6E9 + i;
  for (int i=0; i<b.length; ++i) b[i] = 0x1BCD_8763 - i*546;
  
  a[$-1] |= 0x8000_0000;
  uint [] r = new uint[a.length];
  uint [] q = new uint[b.length-a.length+1];
 
  divModInternal(q, r, b, a);
  q = q[0..$-1];
  uint [] r1 = r.dup;
  uint [] q1 = q.dup;  
  fastDivMod(q, b, a);
  r = b[0..a.length];
  assert(r[]==r1[]);
  assert(q[]==q1[]);
}
}
