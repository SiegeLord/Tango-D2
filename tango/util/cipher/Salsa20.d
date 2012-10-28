/**
 * Copyright: Copyright (C) Thomas Dixon 2009. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.Salsa20;

private import tango.util.cipher.Cipher;

/** Implementation of Salsa20 designed by Daniel J. Bernstein. */
class Salsa20 : StreamCipher
{
    protected
    {
        // Constants
        __gshared immutable immutable(ubyte)[] sigma = cast(immutable(ubyte)[])"expand 32-byte k";
        __gshared immutable immutable(ubyte)[] tau = cast(immutable(ubyte)[])"expand 16-byte k";
        
        // Counter indexes (added for ChaCha)            
        uint i0, i1;
                      
        // Internal state              
        uint[] state;
        
        // Keystream and index marker
        ubyte[] keyStream;
        uint index;
        
        // Internal copies of the key and IV for resetting the cipher
        const(ubyte)[] workingKey,
                       workingIV;
    }
    
    this()
    {
        state = new uint[16];
        
        // State expanded into bytes
        keyStream = new ubyte[64];
        
        i0 = 8;
        i1 = 9;
    }

    this(bool encrypt, ubyte[] key, ubyte[] iv) {
        this();
        init(encrypt, key, iv);
    }

    void init(bool encrypt, ubyte[] key, ubyte[] iv)
    {
        if (key)
        {
            if (key.length != 16 && key.length != 32)
                invalid(name()~": Invalid key length. (requires 16 or 32 bytes)");
            
            workingKey = key;
            keySetup();
            
            index = 0;
        }
        
        if (!workingKey)
            invalid(name()~": Key not set.");
            
        if (!iv || iv.length != 8)
            invalid(name()~": 8 byte IV required.");
            
        workingIV = iv;
        ivSetup();
        
        _encrypt = _initialized = true;
    }
    
    @property override const(char[]) name()
    {
        return "Salsa20";
    }
    
    override ubyte returnByte(ubyte input)
    {
        if (!_initialized)
            invalid (name()~": Cipher not initialized");
            
        if (index == 0) {
            salsa20WordToByte(state, keyStream);
            state[i0]++;
            if (!state[i0])
                state[i1]++;
            // As in djb's, changing the IV after 2^70 bytes is the user's responsibility
            // lol glwt
        }
        
        ubyte result = (keyStream[index]^input);
        index = (index + 1) & 0x3f;
        
        return result;
    }
    
    override uint update(const(void[]) input_, void[] output_)
    {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        const(ubyte[]) input = cast(const(ubyte[])) input_;
        ubyte[] output = cast(ubyte[]) output_;
            
        if (input.length > output.length)
            invalid(name()~": Output buffer too short");
            
        for (int i = 0; i < input.length; i++)
        {
            if (index == 0)
            {
                salsa20WordToByte(state, keyStream);
                state[i0]++;
                if (!state[i0])
                    state[i1]++;
                // As in djb's, changing the IV after 2^70 bytes is the user's responsibility
                // lol glwt
            }
            output[i] = (keyStream[index]^input[i]);
            index = (index + 1) & 0x3f; 
        }
        
        return cast(uint)input.length;
    }
    
    override void reset()
    {
        keySetup();
        ivSetup();
        index = 0;
    }
    
    protected void keySetup()
    {
        uint offset;
        const(ubyte)[] constants;
        
        state[1] = ByteConverter.LittleEndian.to!(uint)(workingKey[0..4]);
        state[2] = ByteConverter.LittleEndian.to!(uint)(workingKey[4..8]);
        state[3] = ByteConverter.LittleEndian.to!(uint)(workingKey[8..12]);
        state[4] = ByteConverter.LittleEndian.to!(uint)(workingKey[12..16]);
        
        if (workingKey.length == 32)
        {
            constants = sigma;
            offset = 16;
        } else
            constants = tau;
            
        state[11] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset..offset+4]);
        state[12] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+4..offset+8]);
        state[13] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+8..offset+12]);
        state[14] = ByteConverter.LittleEndian.to!(uint)(workingKey[offset+12..offset+16]);
        state[ 0] = ByteConverter.LittleEndian.to!(uint)(constants[0..4]);
        state[ 5] = ByteConverter.LittleEndian.to!(uint)(constants[4..8]);
        state[10] = ByteConverter.LittleEndian.to!(uint)(constants[8..12]);
        state[15] = ByteConverter.LittleEndian.to!(uint)(constants[12..16]);
    }
    
    protected void ivSetup()
    {
        state[6] = ByteConverter.LittleEndian.to!(uint)(workingIV[0..4]);
        state[7] = ByteConverter.LittleEndian.to!(uint)(workingIV[4..8]);
        state[8] = state[9] = 0;
    }
    
    protected void salsa20WordToByte(const(uint[]) input, ref ubyte[] output)
    {
        uint[] x = new uint[16];
        x[] = input[0..16];
        
        int i;
        for (i = 0; i < 10; i++)
        {
            x[ 4] ^= Bitwise.rotateLeft(x[ 0]+x[12],  7u);
            x[ 8] ^= Bitwise.rotateLeft(x[ 4]+x[ 0],  9u);
            x[12] ^= Bitwise.rotateLeft(x[ 8]+x[ 4], 13u);
            x[ 0] ^= Bitwise.rotateLeft(x[12]+x[ 8], 18u);
            x[ 9] ^= Bitwise.rotateLeft(x[ 5]+x[ 1],  7u);
            x[13] ^= Bitwise.rotateLeft(x[ 9]+x[ 5],  9u);
            x[ 1] ^= Bitwise.rotateLeft(x[13]+x[ 9], 13u);
            x[ 5] ^= Bitwise.rotateLeft(x[ 1]+x[13], 18u);
            x[14] ^= Bitwise.rotateLeft(x[10]+x[ 6],  7u);
            x[ 2] ^= Bitwise.rotateLeft(x[14]+x[10],  9u);
            x[ 6] ^= Bitwise.rotateLeft(x[ 2]+x[14], 13u);
            x[10] ^= Bitwise.rotateLeft(x[ 6]+x[ 2], 18u);
            x[ 3] ^= Bitwise.rotateLeft(x[15]+x[11],  7u);
            x[ 7] ^= Bitwise.rotateLeft(x[ 3]+x[15],  9u);
            x[11] ^= Bitwise.rotateLeft(x[ 7]+x[ 3], 13u);
            x[15] ^= Bitwise.rotateLeft(x[11]+x[ 7], 18u);
            x[ 1] ^= Bitwise.rotateLeft(x[ 0]+x[ 3],  7u);
            x[ 2] ^= Bitwise.rotateLeft(x[ 1]+x[ 0],  9u);
            x[ 3] ^= Bitwise.rotateLeft(x[ 2]+x[ 1], 13u);
            x[ 0] ^= Bitwise.rotateLeft(x[ 3]+x[ 2], 18u);
            x[ 6] ^= Bitwise.rotateLeft(x[ 5]+x[ 4],  7u);
            x[ 7] ^= Bitwise.rotateLeft(x[ 6]+x[ 5],  9u);
            x[ 4] ^= Bitwise.rotateLeft(x[ 7]+x[ 6], 13u);
            x[ 5] ^= Bitwise.rotateLeft(x[ 4]+x[ 7], 18u);
            x[11] ^= Bitwise.rotateLeft(x[10]+x[ 9],  7u);
            x[ 8] ^= Bitwise.rotateLeft(x[11]+x[10],  9u);
            x[ 9] ^= Bitwise.rotateLeft(x[ 8]+x[11], 13u);
            x[10] ^= Bitwise.rotateLeft(x[ 9]+x[ 8], 18u);
            x[12] ^= Bitwise.rotateLeft(x[15]+x[14],  7u);
            x[13] ^= Bitwise.rotateLeft(x[12]+x[15],  9u);
            x[14] ^= Bitwise.rotateLeft(x[13]+x[12], 13u);
            x[15] ^= Bitwise.rotateLeft(x[14]+x[13], 18u);
        }
        
        for (i = 0; i < 16; i++)
            x[i] += input[i];
            
        int j;    
        for (i = j = 0; i < x.length; i++,j+=int.sizeof)
            ByteConverter.LittleEndian.from!(uint)(x[i], output[j..j+int.sizeof]);
    }
    
    /** Salsa20 test vectors */
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
                "4dfa5e481da23ea09a31022050859936"~ // Expected output
                "da52fcee218005164f267cb65f5cfd7f"~
                "2b4f97e0ff16924a52df269515110a07"~
                "f9e460bc65ef95da58f740b7d1dbb0aa",
                         
                "05e1e7beb697d999656bf37c1b978806"~
                "735d0b903a6007bd329927efbe1b0e2a"~
                "8137c1ae291493aa83a821755bee0b06"~
                "cd14855a67e46703ebf8f3114b584cba",
                 
                "c29ba0da9ebebfacdebbdd1d16e5f598"~
                "7e1cb12e9083d437eaaaa4ba0cdc909e"~
                "53d052ac387d86acda8d956ba9e6f654"~
                "3065f6912a7df710b4b57f27809bafe3",
                
                "5e5e71f90199340304abb22a37b6625b"~
                "f883fb89ce3b21f54a10b81066ef87da"~
                "30b77699aa7379da595c77dd59542da2"~
                "08e5954f89e40eb7aa80a84a6176663f"
            ];

            Salsa20 s20 = new Salsa20();
            ubyte[] buffer = new ubyte[64];
            char[] result;
            for (int i = 0; i < test_keys.length; i++)
            {
                auto key = ByteConverter.hexDecode(test_keys[i]);
                auto params = ByteConverter.hexDecode(test_ivs[i]);
                
                // Encryption
                s20.init(true, key, params);
                s20.update(ByteConverter.hexDecode(test_plaintexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_ciphertexts[i],
                        s20.name()~": ("~result~") != ("~test_ciphertexts[i]~")");           
                
                // Decryption
                s20.init(false, key, params);
                s20.update(ByteConverter.hexDecode(test_ciphertexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_plaintexts[i],
                        s20.name()~": ("~result~") != ("~test_plaintexts[i]~")");
            }   
        }
    }
}
