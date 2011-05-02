/**
 * These functions are built-in intrinsics to the compiler.
 *
 * Intrinsic functions are functions built in to the compiler, usually to take
 * advantage of specific CPU features that are inefficient to handle via
 * external functions.  The compiler's optimizer and code generator are fully
 * integrated in with intrinsic functions, bringing to bear their full power on
 * them. This can result in some surprising speedups.
 * 
 * Note that this module is only present in Tango because the module name is
 * hardcoded into DMD, see http://d.puremagic.com/issues/show_bug.cgi?id=178 
 * To correctly use this functionality in Tango, import tango.core.BitManip.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Walter Bright
 */
module std.intrinsic;


/**
 * Scans the bits in v starting with bit 0, looking
 * for the first set bit.
 * Returns:
 *	The bit number of the first bit set.
 *	The return value is undefined if v is zero.
 */
int bsf( uint v );


/**
 * Scans the bits in v from the most significant bit
 * to the least significant bit, looking
 * for the first set bit.
 * Returns:
 *	The bit number of the first bit set.
 *	The return value is undefined if v is zero.
 * Example:
 * ---
 * import std.intrinsic;
 *
 * int main()
 * {
 *     uint v;
 *     int x;
 *
 *     v = 0x21;
 *     x = bsf(v);
 *     printf("bsf(x%x) = %d\n", v, x);
 *     x = bsr(v);
 *     printf("bsr(x%x) = %d\n", v, x);
 *     return 0;
 * }
 * ---
 * Output:
 *  bsf(x21) = 0<br>
 *  bsr(x21) = 5
 */
int bsr( size_t v );


/**
 * Tests the bit.
 */
int bt( size_t* p, size_t bitnum );


/**
 * Tests and complements the bit.
 */
int btc( size_t* p, size_t bitnum );


/**
 * Tests and resets (sets to 0) the bit.
 */
int btr( size_t* p, size_t bitnum );


/**
 * Tests and sets the bit.
 * Params:
 * p = a non-NULL pointer to an array of size_ts.
 * index = a bit number, starting with bit 0 of p[0],
 * and progressing. It addresses bits like the expression:
---
p[index / (size_t.sizeof*8)] & (1 << (index & ((size_t.sizeof*8) - 1)))
---
 * Returns:
 * 	A non-zero value if the bit was set, and a zero
 *	if it was clear.
 *
 * Example:
 * ---
import std.intrinsic;

int main()
{
    size_t[2] array;

    array[0] = 2;
    array[1] = 0x100;

    printf("btc(array, 35) = %d\n", <b>btc</b>(array, 35));
    printf("array = [0]:x%x, [1]:x%x\n", array[0], array[1]);

    printf("btc(array, 35) = %d\n", <b>btc</b>(array, 35));
    printf("array = [0]:x%x, [1]:x%x\n", array[0], array[1]);

    printf("bts(array, 35) = %d\n", <b>bts</b>(array, 35));
    printf("array = [0]:x%x, [1]:x%x\n", array[0], array[1]);

    printf("btr(array, 35) = %d\n", <b>btr</b>(array, 35));
    printf("array = [0]:x%x, [1]:x%x\n", array[0], array[1]);

    printf("bt(array, 1) = %d\n", <b>bt</b>(array, 1));
    printf("array = [0]:x%x, [1]:x%x\n", array[0], array[1]);

    return 0;
}
 * ---
 * Output:
<pre>
btc(array, 35) = 0
array = [0]:x2, [1]:x108
btc(array, 35) = -1
array = [0]:x2, [1]:x100
bts(array, 35) = 0
array = [0]:x2, [1]:x108
btr(array, 35) = -1
array = [0]:x2, [1]:x100
bt(array, 1) = -1
array = [0]:x2, [1]:x100
</pre>
 */
int bts( size_t* p, size_t bitnum );


/**
 * Swaps bytes in a 4 byte uint end-to-end, i.e. byte 0 becomes
 * byte 3, byte 1 becomes byte 2, byte 2 becomes byte 1, byte 3
 * becomes byte 0.
 */
uint bswap( uint v );


/**
 * Reads I/O port at port_address.
 */
ubyte inp( uint port_address );


/**
 * ditto
 */
ushort inpw( uint port_address );


/**
 * ditto
 */
uint inpl( uint port_address );


/**
 * Writes and returns value to I/O port at port_address.
 */
ubyte outp( uint port_address, ubyte value );


/**
 * ditto
 */
ushort outpw( uint port_address, ushort value );


/**
 * ditto
 */
uint outpl( uint port_address, uint value );
