/**
 * Copyright: Copyright (C) Thomas Dixon 2008. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.TEA;

private import tango.util.cipher.Cipher;

/** Implementation of the TEA cipher designed by
    David Wheeler and Roger Needham. */
class TEA : BlockCipher
{
    private
    {
        static const uint ROUNDS = 32,
                          KEY_SIZE = 16,
                          BLOCK_SIZE = 8,
                          DELTA = 0x9e3779b9u,
                          DECRYPT_SUM = 0xc6ef3720u;
        uint sk0, sk1, sk2, sk3, sum;
    }
    
    final override void reset(){}
    
    final override string name()
    {
        return "TEA";
    }
    
    final override uint blockSize()
    {
        return BLOCK_SIZE;
    }
    
    final void init(bool encrypt, SymmetricKey keyParams)
    {
        _encrypt = encrypt;
                    
        if (keyParams.key.length != KEY_SIZE)
            invalid(name()~": Invalid key length (requires 16 bytes)");
        
        sk0 = ByteConverter.BigEndian.to!(uint)(keyParams.key[0..4]);
        sk1 = ByteConverter.BigEndian.to!(uint)(keyParams.key[4..8]);
        sk2 = ByteConverter.BigEndian.to!(uint)(keyParams.key[8..12]);
        sk3 = ByteConverter.BigEndian.to!(uint)(keyParams.key[12..16]);

        _initialized = true;
    }
    
    final override uint update(void[] input_, void[] output_)
    {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        ubyte[] input = cast(ubyte[]) input_,
                output = cast(ubyte[]) output_;
                    
        if (input.length < BLOCK_SIZE)
            invalid(name()~": Input buffer too short");
            
        if (output.length < BLOCK_SIZE)
            invalid(name()~": Output buffer too short");
        
        uint v0 = ByteConverter.BigEndian.to!(uint)(input[0..4]),
             v1 = ByteConverter.BigEndian.to!(uint)(input[4..8]);
        
        sum = _encrypt ? 0 : DECRYPT_SUM;
        for (int i = 0; i < ROUNDS; i++)
        {
            if (_encrypt)
            {
                sum += DELTA;
                v0 += ((v1 << 4) + sk0) ^ (v1 + sum) ^ ((v1 >> 5) + sk1);
                v1 += ((v0 << 4) + sk2) ^ (v0 + sum) ^ ((v0 >> 5) + sk3);
            }
            else
            {
                v1 -= ((v0 << 4) + sk2) ^ (v0 + sum) ^ ((v0 >> 5) + sk3);
                v0 -= ((v1 << 4) + sk0) ^ (v1 + sum) ^ ((v1 >> 5) + sk1);
                sum -= DELTA;
            }
        }
        
        output[0..4] = ByteConverter.BigEndian.from!(uint)(v0);
        output[4..8] = ByteConverter.BigEndian.from!(uint)(v1);
        
        return BLOCK_SIZE;
    }
    
    /** Some TEA test vectors. */
    debug (UnitTest)
    {
        unittest
        {
            static string[] test_keys = [
                "00000000000000000000000000000000",
                "00000000000000000000000000000000",
                "0123456712345678234567893456789a",
                "0123456712345678234567893456789a"
            ];
                 
            static string[] test_plaintexts = [
                "0000000000000000",
                "0102030405060708",
                "0000000000000000",
                "0102030405060708"
            ];
                
            static string[] test_ciphertexts = [
                "41ea3a0a94baa940",
                "6a2f9cf3fccf3c55",
                "34e943b0900f5dcb",
                "773dc179878a81c0"
            ];
                
            
            TEA t = new TEA();
            foreach (uint i, string test_key; test_keys)
            {
                ubyte[] buffer = new ubyte[t.blockSize];
                string result;
                SymmetricKey key = new SymmetricKey(ByteConverter.hexDecode(test_key));
                
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
