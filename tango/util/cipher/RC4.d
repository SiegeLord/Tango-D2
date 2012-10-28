/**
 * Copyright: Copyright (C) Thomas Dixon 2009. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.RC4;

private import tango.util.cipher.Cipher;

/** Implementation of RC4 designed by Ron Rivest of RSA Security. */
class RC4 : StreamCipher
{
    private
    {
        ubyte[] state;
        const(ubyte)[] workingKey;
        ubyte x, y;
    }
    
    this()
    {
        state = new ubyte[256];
    }

    this(bool encrypt, ubyte[] key) {
        this();
        init(encrypt, key);
    }
    
    final void init(bool encrypt, ubyte[] key)
    {
        if (key.length < 0 || key.length > 256)
            invalid(name()~": Invalid key length (requires 1-256 bytes)");
                
        workingKey = key;
        setup(workingKey);
        
        _encrypt = _initialized = true;
    }
    
    @property final override const(char)[] name()
    {
        return "RC4";
    }
    
    override ubyte returnByte(ubyte input)
    {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        y += state[++x];
        ubyte t = state[x];
        state[x] = state[y];
        state[y] = t;
        
        return (input^state[cast(ubyte)(state[x]+state[y])]);
    }
    
    final override uint update(const(void[]) input_, void[] output_)
    {
        if (!_initialized)
            invalid(name()~": Cipher not initialized");
            
        const(ubyte[]) input = cast(const(ubyte[])) input_;
        ubyte[] output = cast(ubyte[]) output_;
            
        if (input.length > output.length)
            invalid(name()~": Output buffer too short");
            
        for (int i = 0; i < input.length; i++)
        {
            y += state[++x];
            ubyte t = state[x];
            state[x] = state[y];
            state[y] = t;
            output[i] = input[i] ^ state[cast(ubyte)(state[x]+state[y])];
        }
        
        return cast(uint)input.length;
    }
    
    final override void reset()
    { 
        setup(workingKey);
    }
    
    // Do RC4's key setup in a separate method to ease resetting
    private void setup(const(ubyte)[] key)
    {
        for (int i = 0; i < 256; i++)
            state[i] = cast(ubyte)i;
            
        x = 0;
        for (int i = 0; i < 256; i++)
        {
            x += key[i % key.length] + state[i];
            ubyte t = state[i];
            state[i] = state[x];
            state[x] = t;
        }
        
        x = y = 0;
    }
    
    /** Some RC4 test vectors. */
    debug (UnitTest)
    {
        unittest
        {
            __gshared immutable immutable(char)[][] test_keys = [
                "0123456789abcdef",
                "0123456789abcdef",
                "0000000000000000",
                "ef012345",
                "0123456789abcdef"
            ];
                 
            __gshared immutable immutable(char)[][] test_plaintexts = [
                "0123456789abcdef",
                "0000000000000000",
                "0000000000000000",
                "00000000000000000000",
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"~
                "01010101010101010101010101010101"
            ];
                 
            __gshared immutable immutable(char)[][] test_ciphertexts = [
                "75b7878099e0c596",
                "7494c2e7104b0879",
                "de188941a3375d3a",
                "d6a141a7ec3c38dfbd61",
                "7595c3e6114a09780c4ad452338e1ffd"~
                "9a1be9498f813d76533449b6778dcad8"~
                "c78a8d2ba9ac66085d0e53d59c26c2d1"~
                "c490c1ebbe0ce66d1b6b1b13b6b919b8"~
                "47c25a91447a95e75e4ef16779cde8bf"~
                "0a95850e32af9689444fd377108f98fd"~
                "cbd4e726567500990bcc7e0ca3c4aaa3"~
                "04a387d20f3b8fbbcd42a1bd311d7a43"~
                "03dda5ab078896ae80c18b0af66dff31"~
                "9616eb784e495ad2ce90d7f772a81747"~
                "b65f62093b1e0db9e5ba532fafec4750"~
                "8323e671327df9444432cb7367cec82f"~
                "5d44c0d00b67d650a075cd4b70dedd77"~
                "eb9b10231b6b5b741347396d62897421"~
                "d43df9b42e446e358e9c11a9b2184ecb"~
                "ef0cd8e7a877ef968f1390ec9b3d35a5"~
                "585cb009290e2fcde7b5ec66d9084be4"~
                "4055a619d9dd7fc3166f9487f7cb2729"~ 
                "12426445998514c15d53a18c864ce3a2"~ 
                "b7555793988126520eacf2e3066e230c"~  
                "91bee4dd5304f5fd0405b35bd99c7313"~
                "5d3d9bc335ee049ef69b3867bf2d7bd1"~
                "eaa595d8bfc0066ff8d31509eb0c6caa"~
                "006c807a623ef84c3d33c195d23ee320"~
                "c40de0558157c822d4b8c569d849aed5"~
                "9d4e0fd7f379586b4b7ff684ed6a189f"~
                "7486d49b9c4bad9ba24b96abf924372c"~
                "8a8fffb10d55354900a77a3db5f205e1"~
                "b99fcd8660863a159ad4abe40fa48934"~
                "163ddde542a6585540fd683cbfd8c00f"~
                "12129a284deacc4cdefe58be7137541c"~
                "047126c8d49e2755ab181ab7e940b0c0"
            ];
    
            RC4 r = new RC4();
            foreach (uint i, immutable(char)[] test_key; test_keys)
            {
                ubyte[] buffer = new ubyte[test_plaintexts[i].length>>1];
                char[] result;
                
                r.init(true, ByteConverter.hexDecode(test_key));
                
                // Encryption
                r.update(ByteConverter.hexDecode(test_plaintexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_ciphertexts[i],
                        r.name~": ("~result~") != ("~test_ciphertexts[i]~")");
                        
                r.reset();
                
                // Decryption
                r.update(ByteConverter.hexDecode(test_ciphertexts[i]), buffer);
                result = ByteConverter.hexEncode(buffer);
                assert(result == test_plaintexts[i],
                        r.name~": ("~result~") != ("~test_plaintexts[i]~")");
            }
        }
    }
}
