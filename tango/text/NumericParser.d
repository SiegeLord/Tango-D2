/*******************************************************************************

        @file NumericParser.d
        
        Copyright (c) 2004 Kris Bell
        
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


        @version        Initial version; February 2006      

        @author         Kris


*******************************************************************************/

module tango.text.NumericParser;

private import  tango.text.Iterator;

private import  tango.convert.Type,
                tango.convert.Atoi,
                tango.convert.Double;


/*******************************************************************************

        Convert readable input from a stream. All input is tokenized from the
        associated buffer, and converted as necessary into the destination. 

*******************************************************************************/

class NumericParserT(T)
{
        alias get opCall;

        private DoubleT!(T)     dbl;
        private AtoiT!(T)       atoi;
        private IteratorT!(T)   iterator;
        private bool            pedantic;

        /***********************************************************************
        
                Construct a NumericParser on the provided iterator. Pedantic
                mode doesn't allow empty tokens.

        ***********************************************************************/
 
        this (IteratorT!(T) iterator, bool pedantic = false)
        {
                this.pedantic = pedantic;
                this.iterator = iterator;
        }

        /***********************************************************************
        

        ***********************************************************************/

        IteratorT!(T) getIterator ()
        {
                return iterator;
        }

        /***********************************************************************
        

        ***********************************************************************/

        void get (byte[] x)
        {
                read (x.ptr, byte.sizeof * x.length, Type.Byte);
        }

        /***********************************************************************
        

        ***********************************************************************/

        void get (int[] x)
        {
                read (x.ptr, int.sizeof * x.length, Type.Int);
        }

        /***********************************************************************
        

        ***********************************************************************/

        void get (long[] x)
        {
                read (x.ptr, long.sizeof * x.length, Type.Long);
        }

        /***********************************************************************
        

        ***********************************************************************/

        void get (double[] x)
        {
                read (x.ptr, double.sizeof * x.length, Type.Double);
        }

        /***********************************************************************
        
        ***********************************************************************/

        uint read (void* src, uint bytes, uint type)
        in {
           // array of 'bit' is not supported ...
           assert (! (type is Type.Bool && bytes > bool.sizeof));
           }
        body
        {
                int length = bytes;

                // get width of elements (note: does not work for bit[])
                int width = Type.widths[type];

                // for all bytes in source ...
                while (bytes)
                      {
                      T[] t = next ();

                      switch (type)
                             {
                             case Type.Bool:
                                  *cast(bool*) src = cast(bool) (t == "true");
                                  break;

                             case Type.Byte:
                             case Type.UByte:
                                  *cast(ubyte*) src = cast(ubyte) atoi.parse (t);
                                  break;

                             case Type.Short:
                             case Type.UShort:
                                  *cast(ushort*) src = cast(ushort) atoi.parse (t);
                                  break;

                             case Type.Int:
                             case Type.UInt:
                                  *cast(uint*) src = cast(uint) atoi.parse (t);
                                  break;

                             case Type.Long:
                             case Type.ULong:
                                  *cast(long*) src = atoi.parse (t);
                                  break;

                             case Type.Float:
                                  *cast(float*) src = dbl.parse (t);
                                  break;

                             case Type.Double:
                                  *cast(double*) src = dbl.parse (t);
                                  break;

                             case Type.Real:
                                  *cast(real*) src = dbl.parse (t);
                                  break;

                             default:
                                  error ("NumericParser :: unknown type handed to read()");
                             }

                      // bump counters and loop around for next instance
                      bytes -= width;
                      src += width;
                      }

                return length;
        }

        /***********************************************************************
        
                Internal method to capture the next token.

        ***********************************************************************/

        T[] next ()
        {
                do {
                   if (! iterator.next)
                          error ("NumericParser :: unexpected end of input"); 

                   } while (iterator.trim.get.length is 0 && pedantic);

                return iterator.get;
        }

        /***********************************************************************
        
        ***********************************************************************/

        void error (char[] msg)
        {
                throw new Exception (msg);
        }
}

alias NumericParserT!(char) NumericParser;


