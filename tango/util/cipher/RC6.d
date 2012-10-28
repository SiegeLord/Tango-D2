/**
 * Copyright: Copyright (C) Thomas Dixon 2008. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.RC6;

private import tango.util.cipher.Cipher;

/**
 * Implementation of the RC6-32/20/b cipher designed by 
 * Ron Rivest et al. of RSA Security.
 * 
 * It should be noted that this algorithm is very similar to RC5.
 * Currently there are no plans to implement RC5, but should that change
 * in the future, it may be wise to rewrite both RC5 and RC6 to use some
 * kind of template or base class.
 *
 * This algorithm is patented and trademarked.
 * 
 * References: http://people.csail.mit.edu/rivest/Rc6.pdf
 */
class RC6 : BlockCipher
{
    private
    {
        enum uint ROUNDS = 20,
                          BLOCK_SIZE = 16,
                          // Magic constants for a 32 bit word size
                          P = 0xb7e15163,
                          Q = 0x9e3779b9;
        uint[] S;
        const(ubyte)[] workingKey;
    }

    this() {}
    this(bool encrypt, ubyte[] key) {
        this();
        init(encrypt, key);
    }

    @property final override const(char)[] name()
    {
        return "RC6";
    }
    
    @property final override const uint blockSize()
    {
        return BLOCK_SIZE;
    }
    
    final void init(bool encrypt, ubyte[] key)
    {
        _encrypt = encrypt;
        
        auto len = key.length;
        if (len != 16 && len != 24 && len != 32)
            invalid(name()~": Invalid key length (requires 16/24/32 bytes)");
        
        S = new uint[2*ROUNDS+4];        
                   
        workingKey = key;
        setup(workingKey);
        
        _initialized = true;
    }
    
    final override uint update(const(void[]) input_, void[] output_) {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        const(ubyte[]) input = cast(const(ubyte[])) input_;
        ubyte[] output = cast(ubyte[]) output_;
                    
        if (input.length < BLOCK_SIZE)
            invalid(name()~": Input buffer too short");
            
        if (output.length < BLOCK_SIZE)
            invalid(name()~": Output buffer too short");
        
        uint A = ByteConverter.LittleEndian.to!(uint)(input[0..4]),
             B = ByteConverter.LittleEndian.to!(uint)(input[4..8]),
             C = ByteConverter.LittleEndian.to!(uint)(input[8..12]),
             D = ByteConverter.LittleEndian.to!(uint)(input[12..16]),
             t,
             u;
             
        if (_encrypt)
        {
            B += S[0];
            D += S[1];
            
            for (int i = 1; i <= ROUNDS; i++)
            {
                t = Bitwise.rotateLeft(B*((B<<1)+1), 5u);
                u = Bitwise.rotateLeft(D*((D<<1)+1), 5u);
                A = Bitwise.rotateLeft(A^t, u) + S[i<<1];
                C = Bitwise.rotateLeft(C^u, t) + S[(i<<1)+1];
                t = A;
                A = B;
                B = C;
                C = D;
                D = t;
            }
            
            A += S[2*ROUNDS+2];
            C += S[2*ROUNDS+3];
        }
        else
        {
            C -= S[2*ROUNDS+3];
            A -= S[2*ROUNDS+2];
            
            for (int i = ROUNDS; i >= 1; i--)
            {
                t = D;
                D = C;
                C = B;
                B = A;
                A = t;
                u = Bitwise.rotateLeft(D*((D<<1)+1), 5u);
                t = Bitwise.rotateLeft(B*((B<<1)+1), 5u);
                C = Bitwise.rotateRight(C-S[(i<<1)+1], t) ^ u;
                A = Bitwise.rotateRight(A-S[i<<1], u) ^ t;
            }
            
            D -= S[1];
            B -= S[0];
        }

        ByteConverter.LittleEndian.from!(uint)(A, output[0..4]);
        ByteConverter.LittleEndian.from!(uint)(B, output[4..8]);
        ByteConverter.LittleEndian.from!(uint)(C, output[8..12]);
        ByteConverter.LittleEndian.from!(uint)(D, output[12..16]);
        
        return BLOCK_SIZE;
    }
    
    final override void reset()
    {
        setup(workingKey);
    }
    
    private void setup(const(ubyte)[] key)
    {
        size_t c = key.length/4;
        uint[] L = new uint[c];
        for (int i = 0, j = 0; i < c; i++, j+=4)
            L[i] = ByteConverter.LittleEndian.to!(uint)(key[j..j+int.sizeof]);
            
        S[0] = P;
        for (int i = 1; i <= 2*ROUNDS+3; i++)
            S[i] = S[i-1] + Q;
            
        uint A, B, i, j, v = 3*(2*ROUNDS+4); // Relying on ints initializing to 0   
        for (int s = 1; s <= v; s++)
        {
            A = S[i] = Bitwise.rotateLeft(S[i]+A+B, 3u);
            B = L[j] = Bitwise.rotateLeft(L[j]+A+B, A+B);
            i = (i + 1) % (2*ROUNDS+4);
            j = (j + 1) % c;
        }
    }
    
    /** Some RC6 test vectors from the spec. */
    debug (UnitTest)
    {
        unittest
        {
            __gshared immutable immutable(char)[][] test_keys = [
                "00000000000000000000000000000000",
                "0123456789abcdef0112233445566778",
                "00000000000000000000000000000000"~
                "0000000000000000",
                "0123456789abcdef0112233445566778"~
                "899aabbccddeeff0",
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000",
                "0123456789abcdef0112233445566778"~
                "899aabbccddeeff01032547698badcfe"
            ];
                 
            __gshared immutable immutable(char)[][] test_plaintexts = [
                "00000000000000000000000000000000",
                "02132435465768798a9bacbdcedfe0f1",
                "00000000000000000000000000000000",
                "02132435465768798a9bacbdcedfe0f1",
                "00000000000000000000000000000000",
                "02132435465768798a9bacbdcedfe0f1"
            ];
                
            __gshared immutable immutable(char)[][] test_ciphertexts = [
                "8fc3a53656b1f778c129df4e9848a41e",
                "524e192f4715c6231f51f6367ea43f18",
                "6cd61bcb190b30384e8a3f168690ae82",
                "688329d019e505041e52e92af95291d4",
                "8f5fbd0510d15fa893fa3fda6e857ec2",
                "c8241816f0d7e48920ad16a1674e5d48"
            ];
                
            RC6 t = new RC6();
            foreach (uint i, immutable(char)[] test_key; test_keys)
            {
                ubyte[] buffer = new ubyte[t.blockSize];
                char[] result;
                auto key = ByteConverter.hexDecode(test_key);
                
                // Encryption
                t.init(true, key);
                t.update(ByteConverter.hexDecode(test_plaintexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_ciphertexts[i],
                        t.name~": ("~result~") != ("~test_ciphertexts[i]~")");
            
                // Decryption
                t.init(false, key);
                t.update(ByteConverter.hexDecode(test_ciphertexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_plaintexts[i],
                        t.name~": ("~result~") != ("~test_plaintexts[i]~")");
            }
        }
    }
}
