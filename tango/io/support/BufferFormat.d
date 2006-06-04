/*******************************************************************************

        @file BufferFormat.d
        
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

        
        @version        Initial version; December 2005

        @author         Kris


*******************************************************************************/

module tango.io.support.BufferFormat;

private import  tango.convert.Format,
                tango.convert.Double;

private import  tango.io.support.BufferCodec;

private import  tango.io.model.IBuffer;


/*******************************************************************************

        A bridge between a Format instance and a Buffer. This is used for
        the Print & Error globals, but can be used for general-purpose
        buffer-formatting as desired. The Template type 'T' dictates the 
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32)

*******************************************************************************/

class BufferFormatT(T) : FormatClassT!(T)
{
        private T[]             tail;
        private bool            flush;
        private IBuffer         buffer;
        private Importer        importer;

        /**********************************************************************

                Construct a BufferFormat instance, tying the provided
                buffer to a formatter. Set option 'flush' to true if
                the result should be flushed when complete, and provide
                a 'tail' to append on the completed output (such as a 
                newline).

        **********************************************************************/

        this (IBuffer buffer, bool flush = false, T[] tail = null)
        {
                // configure the formatter
                super (&write, &render, &Double.format);

                // hook up a unicode converter
                importer = new UnicodeImporter!(T)(buffer);

                // save buffer and tail references
                this.buffer = buffer;
                this.flush = flush;
                this.tail = tail;
        }
                
        /**********************************************************************

                return the associated buffer

        **********************************************************************/

        IBuffer getBuffer ()
        {
                return buffer;
        }      

        /**********************************************************************

                Callback from the Format instance to write an array

        **********************************************************************/

        private uint write (void[] x, uint type)
        {
                return importer (x, x.length, type);
        }      

        /**********************************************************************

                Callback from the Format instance to render the content

        **********************************************************************/

        private void render ()
        {
                if (tail.length)
                    buffer.append (tail);

                if (flush)
                    buffer.flush ();
        }      
}


// convenience alias
alias BufferFormatT!(char) BufferFormat;
