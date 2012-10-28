/**
 * Copyright: Copyright (C) Thomas Dixon 2009. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.ChaCha;

private import tango.util.cipher.Cipher;
private import tango.util.cipher.Salsa20;

/** Implementation of ChaCha designed by Daniel J. Bernstein. */
class ChaCha : Salsa20
{
    @property override const(char)[] name()
    {
        return "ChaCha";
    }
    
    this()
    {
        i0 = 12;
        i1 = 13;
    }

    this(bool encrypt, ubyte[] key, ubyte[] iv) {
        this();
        init(encrypt, key, iv);
    }

    override protected void keySetup()
    {
        uint offset;
        const(ubyte)[] constants;
        
        state[4] = ByteConverter.LittleEndian.to!(uint)(workingKey[0..4]);
        state[5] = ByteConverter.LittleEndian.to!(uint)(workingKey[4..8]);
        state[6] = ByteConverter.LittleEndian.to!(uint)(workingKey[8..12]);
        state[7] = ByteConverter.LittleEndian.to!(uint)(workingKey[12..16]);
        
        if (workingKey.length == 32)
        {
            constants = sigma;
            offset = 16;
        } else
            constants = tau;
            
        state[ 8] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset..offset+4]);
        state[ 9] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+4..offset+8]);
        state[10] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+8..offset+12]);
        state[11] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+12..offset+16]);
        state[ 0] = ByteConverter.LittleEndian.to!(uint)(constants[0..4]);
        state[ 1] = ByteConverter.LittleEndian.to!(uint)(constants[4..8]);
        state[ 2] = ByteConverter.LittleEndian.to!(uint)(constants[8..12]);
        state[ 3] = ByteConverter.LittleEndian.to!(uint)(constants[12..16]);
    }
    
    override protected void ivSetup()
    {
        state[12] = state[13] = 0;
        state[14] = ByteConverter.LittleEndian.to!(uint)(workingIV[0..4]);
        state[15] = ByteConverter.LittleEndian.to!(uint)(workingIV[4..8]);
    }
    
    override protected void salsa20WordToByte(const(uint[]) input, ref ubyte[] output)
    {
        uint[] x = new uint[16];
        x[] = input[0..16];
          
        int i;
        for (i = 0; i < 4; i++)
        {
            x[ 0] += x[ 4]; x[12] = Bitwise.rotateLeft(x[12]^x[ 0], 16u);
            x[ 8] += x[12]; x[ 4] = Bitwise.rotateLeft(x[ 4]^x[ 8], 12u);
            x[ 0] += x[ 4]; x[12] = Bitwise.rotateLeft(x[12]^x[ 0],  8u);
            x[ 8] += x[12]; x[ 4] = Bitwise.rotateLeft(x[ 4]^x[ 8],  7u);
            x[ 1] += x[ 5]; x[13] = Bitwise.rotateLeft(x[13]^x[ 1], 16u);
            x[ 9] += x[13]; x[ 5] = Bitwise.rotateLeft(x[ 5]^x[ 9], 12u);
            x[ 1] += x[ 5]; x[13] = Bitwise.rotateLeft(x[13]^x[ 1],  8u);
            x[ 9] += x[13]; x[ 5] = Bitwise.rotateLeft(x[ 5]^x[ 9],  7u);
            x[ 2] += x[ 6]; x[14] = Bitwise.rotateLeft(x[14]^x[ 2], 16u);
            x[10] += x[14]; x[ 6] = Bitwise.rotateLeft(x[ 6]^x[10], 12u);
            x[ 2] += x[ 6]; x[14] = Bitwise.rotateLeft(x[14]^x[ 2],  8u);
            x[10] += x[14]; x[ 6] = Bitwise.rotateLeft(x[ 6]^x[10],  7u);
            x[ 3] += x[ 7]; x[15] = Bitwise.rotateLeft(x[15]^x[ 3], 16u);
            x[11] += x[15]; x[ 7] = Bitwise.rotateLeft(x[ 7]^x[11], 12u);
            x[ 3] += x[ 7]; x[15] = Bitwise.rotateLeft(x[15]^x[ 3],  8u);
            x[11] += x[15]; x[ 7] = Bitwise.rotateLeft(x[ 7]^x[11],  7u);
            x[ 0] += x[ 5]; x[15] = Bitwise.rotateLeft(x[15]^x[ 0], 16u);
            x[10] += x[15]; x[ 5] = Bitwise.rotateLeft(x[ 5]^x[10], 12u);
            x[ 0] += x[ 5]; x[15] = Bitwise.rotateLeft(x[15]^x[ 0],  8u);
            x[10] += x[15]; x[ 5] = Bitwise.rotateLeft(x[ 5]^x[10],  7u);
            x[ 1] += x[ 6]; x[12] = Bitwise.rotateLeft(x[12]^x[ 1], 16u);
            x[11] += x[12]; x[ 6] = Bitwise.rotateLeft(x[ 6]^x[11], 12u);
            x[ 1] += x[ 6]; x[12] = Bitwise.rotateLeft(x[12]^x[ 1],  8u);
            x[11] += x[12]; x[ 6] = Bitwise.rotateLeft(x[ 6]^x[11],  7u);
            x[ 2] += x[ 7]; x[13] = Bitwise.rotateLeft(x[13]^x[ 2], 16u);
            x[ 8] += x[13]; x[ 7] = Bitwise.rotateLeft(x[ 7]^x[ 8], 12u);
            x[ 2] += x[ 7]; x[13] = Bitwise.rotateLeft(x[13]^x[ 2],  8u);
            x[ 8] += x[13]; x[ 7] = Bitwise.rotateLeft(x[ 7]^x[ 8],  7u);
            x[ 3] += x[ 4]; x[14] = Bitwise.rotateLeft(x[14]^x[ 3], 16u);
            x[ 9] += x[14]; x[ 4] = Bitwise.rotateLeft(x[ 4]^x[ 9], 12u);
            x[ 3] += x[ 4]; x[14] = Bitwise.rotateLeft(x[14]^x[ 3],  8u);
            x[ 9] += x[14]; x[ 4] = Bitwise.rotateLeft(x[ 4]^x[ 9],  7u);
        }
        
        for (i = 0; i < 16; i++)
            x[i] += input[i];
            
        int j;    
        for (i = j = 0; i < x.length; i++,j+=int.sizeof)
            ByteConverter.LittleEndian.from!(uint)(x[i], output[j..j+int.sizeof]);
    }
    
    /** ChaCha test vectors */
    debug (UnitTest)
    {
        unittest
        {
            __gshared immutable immutable(char)[][] test_keys = [
                "80000000000000000000000000000000", 
                "0053a6f94c9ff24598eb3e91e4378add",
                "00002000000000000000000000000000"~
                "00000000000000000000000000000000",
                "0f62b5085bae0154a7fa4da0f34699ec"~
                "3f92e5388bde3184d72a7dd02376c91c"
                
            ];
            
            __gshared immutable immutable(char)[][] test_ivs = [
                "0000000000000000",            
                "0d74db42a91077de",
                "0000000000000000",
                "288ff65dc42b92f9"
            ];
                 
            __gshared immutable immutable(char)[][] test_plaintexts = [
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000",
                
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000",
                
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000",
                
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"~
                "00000000000000000000000000000000"
                
                
            ];
                 
            __gshared immutable immutable(char)[][] test_ciphertexts = [
                "beb1e81e0f747e43ee51922b3e87fb38"~
                "d0163907b4ed49336032ab78b67c2457"~
                "9fe28f751bd3703e51d876c017faa435"~
                "89e63593e03355a7d57b2366f30047c5",
                         
                "509b267e7266355fa2dc0a25c023fce4"~
                "7922d03dd9275423d7cb7118b2aedf22"~
                "0568854bf47920d6fc0fd10526cfe7f9"~
                "de472835afc73c916b849e91eee1f529",
                 
                "653f4a18e3d27daf51f841a00b6c1a2b"~
                "d2489852d4ae0711e1a4a32ad166fa6f"~
                "881a2843238c7e17786ba5162bc019d5"~
                "73849c167668510ada2f62b4ff31ad04",
                
                "db165814f66733b7a8e34d1ffc123427"~
                "1256d3bf8d8da2166922e598acac70f4"~
                "12b3fe35a94190ad0ae2e8ec62134819"~
                "ab61addcccfe99d867ca3d73183fa3fd"
            ];

            ChaCha cc = new ChaCha();
            ubyte[] buffer = new ubyte[64];
            char[] result;
            for (int i = 0; i < test_keys.length; i++)
            {
                auto key = ByteConverter.hexDecode(test_keys[i]);
                auto iv = ByteConverter.hexDecode(test_ivs[i]);
                
                // Encryption
                cc.init(true, key, iv);
                cc.update(ByteConverter.hexDecode(test_plaintexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_ciphertexts[i],
                        cc.name()~": ("~result~") != ("~test_ciphertexts[i]~")");           
                
                // Decryption
                cc.init(false, key, iv);
                cc.update(ByteConverter.hexDecode(test_ciphertexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_plaintexts[i],
                        cc.name()~": ("~result~") != ("~test_plaintexts[i]~")");
            }   
        }
    }
}
