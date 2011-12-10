/*
 * D phobos intrinsics for LDC
 *
 * From GDC ... public domain!
 */
module ldc.bitmanip;

// Check for the right compiler
version(LDC)
{
    // OK
}
else
{
    static assert(false, "This module is only valid for LDC");
}

int bsf(uint v)
{
    uint m = 1;
    uint i;
    for (i = 0; i < 32; i++,m<<=1) {
        if (v&m)
        return i;
    }
    return i; // supposed to be undefined
}

int bsr(size_t v)
{
    size_t m = 0x80000000;
    size_t i;
    for (i = 32; i ; i--,m>>>=1) {
    if (v&m)
        return i-1;
    }
    return i; // supposed to be undefined
}

int bt(size_t* p, size_t bitnum)
{
    return (p[bitnum / (size_t.sizeof*8)] & (1<<(bitnum & ((size_t.sizeof*8)-1)))) ? -1 : 0 ;
}

int btc(size_t* p, size_t bitnum)
{
    size_t* q = p + (bitnum / (size_t.sizeof*8));
    size_t mask = 1 << (bitnum & ((size_t.sizeof*8) - 1));
    int result = *q & mask;
    *q ^= mask;
    return result ? -1 : 0;
}

int btr(size_t* p, size_t bitnum)
{
    size_t* q = p + (bitnum / (size_t.sizeof*8));
    size_t mask = 1 << (bitnum & ((size_t.sizeof*8) - 1));
    int result = *q & mask;
    *q &= ~mask;
    return result ? -1 : 0;
}

int bts(size_t* p, size_t bitnum)
{
    size_t* q = p + (bitnum / (size_t.sizeof*8));
    size_t mask = 1 << (bitnum & ((size_t.sizeof*8) - 1));
    int result = *q & mask;
    *q |= mask;
    return result ? -1 : 0;
}

pragma(intrinsic, "llvm.bswap.i32")
    uint bswap(uint val);

ubyte  inp(uint p) { throw new Exception("inp intrinsic not yet implemented"); }
ushort inpw(uint p) { throw new Exception("inpw intrinsic not yet implemented"); }
uint   inpl(uint p) { throw new Exception("inpl intrinsic not yet implemented"); }

ubyte  outp(uint p, ubyte v) { throw new Exception("outp intrinsic not yet implemented"); }
ushort outpw(uint p, ushort v) { throw new Exception("outpw intrinsic not yet implemented"); }
uint   outpl(uint p, uint v) { throw new Exception("outpl intrinsic not yet implemented"); }
