/**
 * Copyright: Copyright (C) Thomas Dixon 2008. All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Thomas Dixon
 */

module tango.util.cipher.Cipher;

private import tango.core.Exception : IllegalArgumentException;

/** Base symmetric cipher class */
abstract class Cipher
{
    enum bool ENCRYPT = true,
              DECRYPT = false;
                      
    protected bool _initialized,
                   _encrypt;
    
    /**
     * Process a block of plaintext data from the input array
     * and place it in the output array.
     *
     * Params:
     *     input_  = Array containing input data.
     *     output_  = Array to hold the output data.
     *
     * Returns: The amount of encrypted data processed.
     */
    abstract uint update(const(void[]) input_, void[] output_);
    
    /** Returns: The name of the algorithm of this cipher. */
    @property abstract const(char)[] name();
    
    /** Reset cipher to its state immediately subsequent the last init. */
    abstract void reset();
   
    /**
     * throw an InvalidArgument exception
     * 
     * Params:
     *     msg = message to associate with the exception
     */
    static void invalid (const(char[]) msg)
    {
        throw new IllegalArgumentException (msg.idup);
    }
     
    /** Returns: Whether or not the cipher has been initialized. */
    final const bool initialized()
    {
        return _initialized;
    }
}



/** Interface for a standard block cipher. */
abstract class BlockCipher : Cipher
{
    /** Returns: The block size in bytes that this cipher will operate on. */
    @property abstract const uint blockSize();
}


/** Interface for a standard stream cipher. */
abstract class StreamCipher : Cipher
{   
    /**
     * Process one byte of input.
     *
     * Params:
     *     input = Byte to XOR with keystream.
     *
     * Returns: One byte of input XORed with the keystream.
     */
    abstract ubyte returnByte(ubyte input);
}

 
 /** Base padding class for implementing block padding schemes. */
 abstract class BlockCipherPadding
 {
    /** Returns: The name of the padding scheme implemented. */
    @property abstract const(char)[] name();

    /**
    * Generate padding to a specific length.
    *
    * Params:
    *     len = Length of padding to generate
    *
    * Returns: The padding bytes to be added.
    */ 
    abstract ubyte[] pad(uint len);

    /**
    * Return the number of pad bytes in the block.
    *
    * Params:
    *     input_ = Padded block of which to count the pad bytes.
    *
    * Returns: The number of pad bytes in the block.
    *
    * Throws: dcrypt.crypto.errors.InvalidPaddingError if 
    *         pad length cannot be discerned.
    */
    abstract uint unpad(const(void[]) input_);
 }

struct Bitwise
{
    static uint rotateLeft(uint x, uint y)
    {
        return (x << y) | (x >> (32u-y));
    }
    
    static uint rotateRight(uint x, uint y)
    {
        return (x >> y) | (x << (32u-y));    
    }
    
    static ulong rotateLeft(ulong x, uint y)
    {
        return (x << y) | (x >> (64u-y));
    }
    
    static ulong rotateRight(ulong x, uint y)
    {
        return (x >> y) | (x << (64u-y));    
    }
}


/** Converts between integral types and unsigned byte arrays */
struct ByteConverter
{
    private __gshared immutable immutable(char)[] hexits = "0123456789abcdef";
    private __gshared immutable immutable(char)[] base32digits = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    
    /** Conversions between little endian integrals and bytes */
    struct LittleEndian
    {
        /**
         * Converts the supplied array to integral type T
         * 
         * Params:
         *     x_ = The supplied array of bytes (ubytes, bytes, chars, whatever)
         * 
         * Returns:
         *     A integral of type T created with the supplied bytes placed
         *     in the specified byte order.
         */
        static T to(T)(const(void[]) x_)
        {
            const(ubyte[]) x = cast(const(ubyte[]))x_;
            
            T result = ((cast(T)x[0])       |
                       ((cast(T)x[1]) << 8));
                       
            static if (T.sizeof >= int.sizeof)
            {
                result |= ((cast(T)x[2]) << 16) |
                          ((cast(T)x[3]) << 24);
            }
            
            static if (T.sizeof >= long.sizeof)
            {
                result |= ((cast(T)x[4]) << 32) |
                          ((cast(T)x[5]) << 40) |
                          ((cast(T)x[6]) << 48) |
                          ((cast(T)x[7]) << 56);
            }
            
            return result;
        }
        
        /**
         * Converts the supplied integral to an array of unsigned bytes.
         * 
         * Params:
         *     input = Integral to convert to bytes
         * 
         * Returns:
         *     Integral input of type T split into its respective bytes
         *     with the bytes placed in the specified byte order.
         */
        static void from(T)(T input, ubyte[] output)
        {
            output[0] = cast(ubyte)(input);
            output[1] = cast(ubyte)(input >> 8);
            
            static if (T.sizeof >= int.sizeof)
            {
                output[2] = cast(ubyte)(input >> 16);
                output[3] = cast(ubyte)(input >> 24);
            }
            
            static if (T.sizeof >= long.sizeof)
            {
                output[4] = cast(ubyte)(input >> 32);
                output[5] = cast(ubyte)(input >> 40);
                output[6] = cast(ubyte)(input >> 48);
                output[7] = cast(ubyte)(input >> 56);
            }
        }
    }
    
    /** Conversions between big endian integrals and bytes */
    struct BigEndian
    {
        
        static T to(T)(const(void[]) x_)
        {
            const(ubyte[]) x = cast(const(ubyte[]))x_;
            
            static if (is(T == ushort) || is(T == short))
            {
                return cast(T) (((x[0] & 0xff) << 8) |
                                 (x[1] & 0xff));
            }
            else static if (is(T == uint) || is(T == int))
            {
                return cast(T) (((x[0] & 0xff) << 24) |
                                ((x[1] & 0xff) << 16) |
                                ((x[2] & 0xff) << 8)  |
                                 (x[3] & 0xff));
            }
            else static if (is(T == ulong) || is(T == long))
            {
                return cast(T) ((cast(T)(x[0] & 0xff) << 56) |
                                (cast(T)(x[1] & 0xff) << 48) |
                                (cast(T)(x[2] & 0xff) << 40) |
                                (cast(T)(x[3] & 0xff) << 32) |
                                ((x[4] & 0xff) << 24) |
                                ((x[5] & 0xff) << 16) |
                                ((x[6] & 0xff) << 8)  |
                                 (x[7] & 0xff));
            }
        }
        
        static void from(T)(T input, ubyte[] output)
        {
            static if (T.sizeof == long.sizeof)
            {
                output[0] = cast(ubyte)(input >> 56);
                output[1] = cast(ubyte)(input >> 48);
                output[2] = cast(ubyte)(input >> 40);
                output[3] = cast(ubyte)(input >> 32);
                output[4] = cast(ubyte)(input >> 24);
                output[5] = cast(ubyte)(input >> 16);
                output[6] = cast(ubyte)(input >> 8);
                output[7] = cast(ubyte)(input);
            }
            else static if (T.sizeof == int.sizeof)
            {
                output[0] = cast(ubyte)(input >> 24);
                output[1] = cast(ubyte)(input >> 16);
                output[2] = cast(ubyte)(input >> 8);
                output[3] = cast(ubyte)(input);
            }
            else static if (T.sizeof == short.sizeof)
            {
                output[0] = cast(ubyte)(input >> 8);
                output[1] = cast(ubyte)(input);
            }
        }
    }

    static char[] hexEncode(const(void[]) input_)
    {
        const(ubyte[]) input = cast(const(ubyte[]))input_;
        char[] output = new char[input.length<<1];
        
        int i = 0;
        foreach (ubyte j; input)
        { 
            output[i++] = hexits[j>>4];
            output[i++] = hexits[j&0xf];
        }
        
        return output;    
    }
    
    static char[] base32Encode(const(void[]) input_, bool doPad=true)
    {
        if (!input_)
            return "".dup;
        const(ubyte[]) input = cast(const(ubyte[]))input_;
        char[] output;
        auto inputbits = input.length*8;
        auto inputquantas = inputbits / 40;
        if (inputbits % 40)
            output = new char[(inputquantas+1) * 8];
        else
            output = new char[inputquantas * 8];

        int i = 0;
        ushort remainder;
        ubyte remainlen;
        foreach (ubyte j; input)
        {
            remainder = cast(ushort)(remainder<<8) | j;
            remainlen += 8;
            while (remainlen > 5) {
                output[i++] = base32digits[(remainder>>(remainlen-5))&0b11111];
                remainlen -= 5;
            }
        }
        if (remainlen)
            output[i++] = base32digits[(remainder<<(5-remainlen))&0b11111];
        while (doPad && (i < output.length)) {
            output[i++] = '=';
        }

        return output[0..i];
    }

    static ubyte[] hexDecode(const(char[]) input)
    {
        char[] inputAsLower = stringToLower(input);
        ubyte[] output = new ubyte[input.length>>1];
        
        static __gshared ubyte[char] hexitIndex;
        for (int i = 0; i < hexits.length; i++)
            hexitIndex[hexits[i]] = cast(ubyte) i;
            
        for (int i = 0, j = 0; i < output.length; i++)
        {
            output[i] = cast(ubyte) (hexitIndex[inputAsLower[j++]] << 4);
            output[i] |= hexitIndex[inputAsLower[j++]]; 
        }
        
        return output;
    }
    
    static ubyte[] base32Decode(const(char[]) input)
    {
        static __gshared ubyte[char] b32Index;
        for (int i = 0; i < base32digits.length; i++)
            b32Index[base32digits[i]] = cast(ubyte) i;

        auto outlen = (input.length*5)/8;
        ubyte[] output = new ubyte[outlen];

        ushort remainder;
        ubyte remainlen;
        size_t oIndex;
        foreach (c; stringToUpper(input))
        {
            if (c == '=')
                continue;
            remainder = cast(ushort)(remainder<<5) | b32Index[c];
            remainlen += 5;
            while (remainlen >= 8) {
                output[oIndex++] = cast(ubyte) (remainder >> (remainlen-8));
                remainlen -= 8;
            }
        }

        return output[0..oIndex];
    }

    private static char[] stringToLower(const(char[]) input)
    {
        char[] output = new char[input.length];
        
        foreach (int i, char c; input) 
            output[i] = cast(char) ((c >= 'A' && c <= 'Z') ? c+32 : c);
            
        return cast(char[])output;
    }

    private static char[] stringToUpper(const(char[]) input)
    {
        char[] output = new char[input.length];

        foreach (int i, char c; input)
            output[i] = cast(char) ((c >= 'a' && c <= 'z') ? c-32 : c);

        return cast(char[])output;
    }
}
