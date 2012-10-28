/**
 * Copyright: Copyright (C) Thomas Dixon 2008. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.XTEA;

private import tango.util.cipher.Cipher;

/** Implementation of the XTEA cipher designed by
    David Wheeler and Roger Needham. */
class XTEA : BlockCipher
{
    private
    {
        enum uint ROUNDS = 32,
                  KEY_SIZE = 16,
                  BLOCK_SIZE = 8,
                  DELTA = 0x9e3779b9u;
        uint[] subkeys,
               sum0,
               sum1;
    }

    this() {}
    this(bool encrypt, ubyte[] key) {
        this();
        init(encrypt, key);
    }

    final override void reset(){}
    
    @property final override const(char)[] name()
    {
        return "XTEA";
    }
    
    @property final override const uint blockSize()
    {
        return BLOCK_SIZE;
    }
    
    final void init(bool encrypt, ubyte[] key)
    {
        _encrypt = encrypt;
                    
        if (key.length != KEY_SIZE)
            invalid(name()~": Invalid key length (requires 16 bytes)");
        
        subkeys = new uint[4];
        sum0 = new uint[32];
        sum1 = new uint[32];
        
        int i, j;
        for (i = j = 0; i < 4; i++, j+=int.sizeof)
            subkeys[i] = ByteConverter.BigEndian.to!(uint)(key[j..j+int.sizeof]);
            
        // Precompute the values of sum + k[] to speed up encryption
        for (i = j = 0; i < ROUNDS; i++)
        {
            sum0[i] = (j + subkeys[j & 3]);
            j += DELTA;
            sum1[i] = (j + subkeys[j >> 11 & 3]);
        }
        
        _initialized = true;
    }
    
    final override uint update(const(void[]) input_, void[] output_)
    {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        const(ubyte[]) input = cast(const(ubyte[])) input_;
        ubyte[] output = cast(ubyte[]) output_;
                    
        if (input.length < BLOCK_SIZE)
            invalid(name()~": Input buffer too short");
            
        if (output.length < BLOCK_SIZE)
            invalid(name()~": Output buffer too short");
        
        uint v0 = ByteConverter.BigEndian.to!(uint)(input[0..4]),
             v1 = ByteConverter.BigEndian.to!(uint)(input[4..8]);
             
        if (_encrypt)
        {
            for (int i = 0; i < ROUNDS; i++)
            {
                v0 += ((v1 << 4 ^ v1 >> 5) + v1) ^ sum0[i];
                v1 += ((v0 << 4 ^ v0 >> 5) + v0) ^ sum1[i];
            }
        }
        else
        {
            for (int i = ROUNDS-1; i >= 0; i--)
            {
                v1 -= (((v0 << 4) ^ (v0 >> 5)) + v0) ^ sum1[i];
                v0 -= (((v1 << 4) ^ (v1 >> 5)) + v1) ^ sum0[i];
            }
        }
        
        ByteConverter.BigEndian.from!(uint)(v0, output[0..4]);
        ByteConverter.BigEndian.from!(uint)(v1, output[4..8]);
        
        return BLOCK_SIZE;
    }
    
    /** Some XTEA test vectors. */
    debug (UnitTest)
    {
        unittest
        {
            __gshared immutable immutable(char)[][] test_keys = [
                "00000000000000000000000000000000",
                "00000000000000000000000000000000",
                "0123456712345678234567893456789a",
                "0123456712345678234567893456789a",
                "00000000000000000000000000000001",
                "01010101010101010101010101010101",
                "0123456789abcdef0123456789abcdef",
                "0123456789abcdef0123456789abcdef",
                "00000000000000000000000000000000",
                "00000000000000000000000000000000"
            ];
                 
            __gshared immutable immutable(char)[][] test_plaintexts = [
                "0000000000000000",
                "0102030405060708",
                "0000000000000000",
                "0102030405060708",
                "0000000000000001",
                "0101010101010101",
                "0123456789abcdef",
                "0000000000000000",
                "0123456789abcdef",
                "4141414141414141"
            ];
                
            __gshared immutable immutable(char)[][] test_ciphertexts = [
                "dee9d4d8f7131ed9",
                "065c1b8975c6a816",
                "1ff9a0261ac64264",
                "8c67155b2ef91ead",
                "9f25fa5b0f86b758",
                "c2eca7cec9b7f992",
                "27e795e076b2b537",
                "5c8eddc60a95b3e1",
                "7e66c71c88897221",
                "ed23375a821a8c2d"
            ];
                
            XTEA t = new XTEA();
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

