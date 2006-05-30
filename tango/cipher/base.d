/*******************************************************************************

        Copyright (c) 2006 Regan Heath
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, February 2006      
                        Modified for Mango, April 2006

        @author         Regan Heath
                        Kris

*******************************************************************************/

module tango.cipher.base;

/*******************************************************************************

*******************************************************************************/

class CipherException : Exception
{
        this(char[] msg) { super(msg); }
}


/*******************************************************************************

*******************************************************************************/

class Digest
{
        abstract char[] toString();
}


/*******************************************************************************

        The idea behind these methods is that you can call sum() if you 
        have all  the data at once (sum calls the other 3, meaning you 
        cannot mix it with  calls to the other).
        
        Or you can call start(), followed by update() any number of times, 
        and finally finish(). These three methods make it easy to integrate  
        with a stream, for example.

        Each concrete implementation defines a trasform method in the form:

                void transform(ubyte[] input);

        which is called by the mixed methods to process the data. In addition 
        the following methods:

                void padMessage(ubyte[] at);
                void padLength(ubyte[] at, ulong length);

        are called to perform the padding, and:

                void extend();

        was required to handle MD2 being a little different to the others.

*******************************************************************************/

class Cipher
{
        private uint    bytes;
        private ubyte[] buffer;

        /***********************************************************************
        
        ***********************************************************************/

        public abstract Digest getDigest();
        
        /***********************************************************************
        
        ***********************************************************************/

        protected abstract uint blockSize();

        /***********************************************************************
        
        ***********************************************************************/

        protected abstract uint addSize();

        /***********************************************************************
        
        ***********************************************************************/

        protected abstract void padMessage(ubyte[] data);

        /***********************************************************************
        
        ***********************************************************************/

        protected abstract void padLength(ubyte[] data, ulong length) {}

        /***********************************************************************
        
        ***********************************************************************/

        protected abstract void transform(ubyte[] data);

        /***********************************************************************
        
        ***********************************************************************/

        protected abstract void extend() {}     
        
        /***********************************************************************
        
        ***********************************************************************/

        this()
        {
                buffer = new ubyte[blockSize()];
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        Digest sum(void[] data)
        {
                start();
                update(data);
                return finish();
        }

        /***********************************************************************
        
        ***********************************************************************/

        void start()
        {
                bytes = 0;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        void update(void[] input)
        {
                uint i;
                ubyte[] data = cast(ubyte[])input;
                
                i = bytes & (blockSize-1);
                bytes += data.length;

                if (data.length+i < blockSize) {
                        buffer[i..i+data.length] = data[];
                        return ;
                }
                
                buffer[i..blockSize] = data[0..blockSize-i];
                transform(buffer);

                for(i = blockSize-i; i+blockSize-1 < data.length; i += blockSize)
                        transform(data[i..i+blockSize]);

                buffer[0..data.length-i] = data[i..data.length];
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        Digest finish()
        {
                uint i;
        
                i = bytes & (blockSize-1);
                if (i < blockSize-addSize) 
                    padMessage(buffer[i..blockSize-addSize]);
                else 
                   {
                   padMessage(buffer[i..blockSize]);
                   transform(buffer);
                   (cast(ubyte[])buffer)[] = 0;
                   }
                
                padLength(buffer[blockSize-addSize..blockSize],bytes);
                transform(buffer);

                extend();
        
                return getDigest();
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        static final void littleEndian32(ubyte[] input, uint[] output)
        {
                output[] = 0;

                assert(output.length == input.length/4);
                for (uint i = 0; i < input.length; i++) 
                    {
                    output[i/4] <<= 8;
                    version (BigEndian) 
                             output[i/4] |= cast(uint)input[i];
                       else 
                          output[i/4] |= cast(uint)input[i^3];
                    }
        }       

        /***********************************************************************
        
        ***********************************************************************/

        static final void bigEndian32(ubyte[] input, uint[] output)
        {               
                output[] = 0;

                assert(output.length == input.length/4);
                for (uint i = 0; i < input.length; i++) 
                    {
                    output[i/4] <<= 8;
                    version (BigEndian) 
                             output[i/4] |= cast(uint)input[i^3];
                       else 
                          output[i/4] |= cast(uint)input[i];
                    }
        }

        /***********************************************************************
        
        ***********************************************************************/

        static final void littleEndian64(ubyte[] input, ulong[] output)
        {
                output[] = 0;

                assert(output.length == input.length/8);
                for (uint i = 0; i < input.length; i++) 
                    {
                    output[i/8] <<= 8;
                    version (BigEndian) 
                             output[i/8] |= cast(ulong)input[i];
                       else 
                          output[i/8] |= cast(ulong)input[i^7];
                    }
        }


        /***********************************************************************
        
        ***********************************************************************/

        static final void bigEndian64(ubyte[] input, ulong[] output)
        {
                output[] = 0;

                assert(output.length == input.length/8);
                for (uint i = 0; i < input.length; i++) 
                    {
                    output[i/8] <<= 8;
                    version (BigEndian) 
                             output[i/8] |= cast(ulong)input[i^7];
                       else 
                          output[i/8] |= cast(ulong)input[i];
                    }
        }

        /***********************************************************************
        
        ***********************************************************************/

        static final uint rotateLeft(uint x, uint n)
        {       
                version (X86) 
                        {
                        asm {
                            naked;
                            mov ECX,EAX;
                            mov EAX,4[ESP];
                            rol EAX,CL;
                            ret 4;
                            }
                        }
                     else 
                        return (x << n) | (x >> (32-n));
        }
}


/*******************************************************************************

*******************************************************************************/

template toHexString(T)
{ 
        char[] toHexString(T d) 
        {
                char[] result;
                static char[] hexdigits = "0123456789ABCDEF";

                if (d.length != 0) 
                   {
                   typeof(d[0]) u;
                   uint sz = u.sizeof*2;
                   uint ndigits = 0;

                   result = new char[sz*d.length];
                   for (int i = d.length-1; i >= 0; i--) 
                       {                  
                       u = d[i];
                       for (; u; u /= 16) 
                           {
                           result[result.length-1-ndigits] = hexdigits[0x0f & cast(uint) u];
                           ndigits++;
                           }

                       for (; ndigits < (d.length-i)*sz; ndigits++)
                              result[result.length-1-ndigits] = '0';
                       }
                   }
                return result;
        }
}

