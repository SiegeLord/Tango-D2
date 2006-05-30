/*******************************************************************************

        file:           _Buffer.d

        copyright:      (c) 2004 Kris Bell; all rights reserved

        authors:        Kris

        version:        Initial version; March 2004

        license:        BSD style
        
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
           of the source, and applies to all variations including, but not
           limited to, original source, derived source, and altered source.

        Copyright (c) 2004 Kris Bell; all rights reserved

*******************************************************************************/

module tango.io.Buffer;

private import  tango.io.Exception;

public  import  tango.io.model.IBuffer;

public  import  tango.io.model.IConduit;


/******************************************************************************

******************************************************************************/

extern (C)
{
        private void * memcpy (void *dst, void *src, uint);
}       

/*******************************************************************************

        The premise behind this IO package is as follows:

        The central concept is that of a buffer. The buffer acts
        as a queue (line) where items are removed from the front
        and new items are added to the back. Buffers are modeled 
        by tango.io.model.IBuffer, and a concrete implementation 
        is provided by this class.
        
        Buffers can be read and written directly, but a Reader, 
        Iterator, and/or Writer are often leveraged to apply 
        structure to what might otherwise be simple raw data. 

        Readers & writers are bound to a buffer; often the same 
        buffer. It's also perfectly legitimate to bind multiple 
        readers to the same buffer; they will access buffer 
        content serially as one would expect. This also applies to
        multiple writers on the same buffer. Readers and writers
        support three styles of IO: put/get, the C++ style << &
        >> operators, and the () whisper style. All operations 
        can be chained.
        
        Any class can be made compatable with the reader/writer
        framework by implementing the IReadable and/or IWritable 
        interfaces. Each of these specify just a single method.
        Once compatable, the class can simply be passed to the 
        reader/writer as if it were native data.
        
        Buffers may also be tokenized by applying an Iterator. 
        This can be handy when one is dealing with text input, 
        and/or the content suits a more fluid format than most 
        typical readers & writers support. Iterator tokens
        are mapped directly onto buffer content (sliced), making 
        them quite efficient in practice. Like Readers, multiple
        iterators can be mapped onto a common buffer; access is
        serialized in a similar fashion.

        Conduits provide virtualized access to external content,
        and represent things like files or Internet connections.
        They are just a different kind of stream. Conduits are
        modelled by tango.io.model.IConduit, and implemented via
        classes FileConduit, SocketConduit, ConsoleConduit, and 
        so on. Additional conduit varieties are easy to construct: 
        one either subclasses tango.io.Conduit, or implements 
        tango.io.model.IConduit. Each conduit reads and writes 
        from/to a buffer in big chunks (typically the entire 
        buffer).

        Conduits may have one or more filters attached. These 
        will process content as it flows back and forth across
        the conduit. Examples of filters include compression, utf
        transcoding, and endian transformation. These filters
        apply to the entire scope of the conduit, rather than
        being specific to one data-type or another. Specific 
        data-type transformations are applied by readers and 
        writers instead, and include operations such as 
        endian-conversion.

        Buffers are sometimes memory-only, in which case there
        is nothing left to do when a reader (or iterator) hits
        end of buffer conditions. Other buffers are themselves 
        bound to a Conduit. When this is the case, a reader will 
        eventually cause the buffer to reload via its associated 
        conduit. Previous buffer content will thus be lost. The
        same approach is applied to writers, whereby they flush 
        the content of a full buffer to a bound conduit before 
        continuing. Another variation is that of a memory-mapped
        buffer, whereby the buffer content is mapped directly to
        virtual memory exposed via the oS. This can be used to 
        address large files as an array of content.

        Readers & writers may have a transcoder attached. The
        role of a transcoder is to aid in converting between each
        representation of text (utf8, utf16, utf32). They're used
        to normalize string I/O according to a standard text-type.
        By default there is no transcoder attached, and the type
        is therefore considered "raw".

        Direct buffer manipulation typically involves appending, 
        as in the following example:
        ---
        // create a small buffer
        auto buf = new Buffer (256);

        auto foo = "to write some D";

        // append some text directly to it
        buf.append("now is the time for all good men ").append(foo);
        ---

        Alternatively, one might use a Writer to append the buffer. 
        This is an example of the 'whisper' style supported by the
        IO package:
        ---
        auto write = new Writer (new Buffer(256));
        write ("now is the time for all good men "c) (foo);
        ---

        Or, using printf-like formatting via a text oriented DisplayWriter:
        ---
        auto write = new DisplayWriter (new Buffer(256));
        write.print ("now is the time for %d good men %s", 3, foo);
        ---

        One might use a GrowBuffer instead, where one wishes to append
        beyond the specified size. 
        
        A common usage of a buffer is in conjunction with a conduit, 
        such as FileConduit. Each conduit exposes a preferred-size for 
        its associated buffers, utilized during buffer construction:
        ---
        auto file = new FileConduit ("file.name");
        auto buf = new Buffer (file);
        ---

        However, this is typically hidden by higher level constructors 
        such as those of Reader and Writer derivitives. For example:
        ---
        auto file = new FileConduit ("file.name");
        auto read = new Reader (file);
        ---

        There is indeed a buffer between the Reader and Conduit, but 
        explicit construction is unecessary in common cases. See both 
        Reader and Writer for examples of formatted IO.

        Stdout is a predefined DisplayWriter, attached to a conduit
        representing the console. Thus, all conduit operations are
        legitimate on Stdout and Stderr. For example:
        ---
        Stdout.conduit.copy (new FileConduit ("readme.txt"));
        ---

        Because Stdout is an instance of DisplayWriter, it also has
        support for formatted output:
        ---
        Stdout.println ("now is the time for %d good men %s", 3, foo);
        ---

        The Stdout writer is attached to a specific buffer, which in
        turn is attached to a specific conduit. This buffer is known 
        as Cout, and it is attached to a conduit representing the 
        console. Cout can be used directly, bypassing the writer layer
        if so desired. 
        
        Cout has relatives named Cerr and Cin, which are attached to 
        the corresponding console conduits. Writer Stderr, and reader 
        Stdin are mapped onto Cerr and Cin respectively, ensuring 
        console IO is buffered in one common area. 
        ---
        Cout ("what is your name?");
        char[] name;
        Cin (name);
        Cout ("hello ") (name) .newline;
        ---

        An Iterator is constructed in a similar manner to a Reader; you
        provide it with a buffer or a conduit. There's a variety of 
        iterators available in the tango.text package, and they are each
        templated for utf8, utf16, and utf32 ~ this example uses a line 
        iterator to sweep a text file:
        ---
        auto file = new FileConduit ("file.name");
        foreach (line; new LineIterator (file))
                 Cout(line).newline;
        ---                 

        Buffers are useful for many purposes within Mango, but there
        are times when it may be more appropriate to sidestep them. For 
        such cases, conduit derivatives (such as FileConduit) support 
        direct array-based IO via a pair of read() and write() methods. 
        These alternate methods will also invoke any attached filters.


*******************************************************************************/

class Buffer : IBuffer
{
        protected void[]        data;           // the raw data
        protected Style         style;          // Text, Binary, Raw
        protected uint          limit;          // limit of valid content
        protected uint          capacity;       // maximum of limit
        protected uint          position;       // current read position
        protected IConduit      conduit;        // optional conduit

        
        protected static char[] overflow  = "output buffer overflow";
        protected static char[] underflow = "input buffer underflow";
        protected static char[] eofRead   = "end-of-file whilst reading";
        protected static char[] eofWrite  = "end-of-file whilst writing";

        /***********************************************************************
        
                Ensure the buffer remains valid between method calls
                 
        ***********************************************************************/

        invariant 
        {
               assert (position <= limit);
               assert (limit <= capacity);
        }

        /***********************************************************************
        
                Construct a Buffer upon the provided conduit. A relevant 
                buffer size is supplied via the provided conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                this (conduit.bufferSize);
                setConduit (conduit);
                this.style = conduit.isTextual ? Text : Binary;
        }

        /***********************************************************************
        
                Construct a Buffer with the specified number of bytes. 

        ***********************************************************************/

        this (uint capacity = 0)
        {
                this (new ubyte[capacity]);              
        }

        /***********************************************************************
        
                Prime buffer with an application-supplied array. There is 
                no readable data present, and writing begins at position 0.

        ***********************************************************************/

        this (void[] data)
        {
                this (data, 0);
        }

        /***********************************************************************
        
                Prime buffer with an application-supplied array, and 
                indicate how much readable data is already there. A
                write operation will begin writing immediately after
                the existing content.

        ***********************************************************************/

        this (void[] data, uint readable)
        {
                setContent (data, readable);
        }

        /***********************************************************************
        
                Throw an exception with the provided message

        ***********************************************************************/

        final void error (char[] msg)
        {
                throw new IOException (msg);
        }

        /***********************************************************************
                
                Return style of buffer. This is either Text, Binary, or Raw.
                The style is initially set via a constructor

        ***********************************************************************/

        Style getStyle ()
        {
                return style;
        }

        /***********************************************************************
        
                Set the backing array with all content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use clear() to reset the
                content (make it all writable).

        ***********************************************************************/

        IBuffer setValidContent (void[] data)
        {
                return setContent (data, data.length);
        }

        /***********************************************************************
        
                Set the backing array with some content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use clear() to reset the
                content (make it all writable).

        ***********************************************************************/

        IBuffer setContent (void[] data, uint readable=0)
        {
                this.data = data;
                this.limit = readable;
                this.capacity = data.length;   

                // reset to start of input
                this.position = 0;

                return this;            
        }

        /***********************************************************************
        
                Read a slice of data from the buffer, loading from the
                conduit as necessary. The specified number of bytes is
                loaded into the buffer, and marked as having been read 
                when the 'eat' parameter is set true. When 'eat' is set
                false, the read position is not adjusted.

                Note that the slice cannot be larger than the size of 
                the buffer ~ use method get(void[]) instead where you
                simply want the content copied, or use conduit.read()
                to extract directly from an attached conduit.

                Returns the corresponding buffer slice when successful, 
                or null if there's not enough data available (Eof; Eob).

        ***********************************************************************/

        void[] get (uint size, bool eat = true)
        {   
                if (size > readable)
                   {
                   if (conduit is null)
                       error (underflow);

                   // make some space? This will try to leave as much content
                   // in the buffer as possible, such that entire records may
                   // be aliased directly from within. 
                   if (size > writable)
                      {
                      if (size > capacity)
                          error (underflow);
                      compress ();
                      }

                   // populate tail of buffer with new content
                   do {
                      if (fill(conduit) == IConduit.Eof)
                          error (eofRead);
                      } while (size > readable);
                   }

                uint i = position;
                if (eat)
                    position += size;
                return data [i .. i + size];               
        }

        /***********************************************************************

                Fill the provided array with content. We try to satisfy 
                the request from the buffer content, and read directly
                from an attached conduit where more is required.

                Returns true if the request was satisfied; false otherwise

        ***********************************************************************/

        bool get (void[] dst)
        {   
                // copy the buffer remains
                int i = readable ();
                if (i > dst.length)
                    i = dst.length;
                dst[0..i] = get(i);

                // and get the rest directly from conduit
                if (i < dst.length)
                    if (conduit)
                        return conduit.fill (dst [i..$]);
                    else
                       return false;
                return true;
        }

        /***********************************************************************
        
                Wait for something to arrive in the buffer. This may stall
                the current thread forever, although usage of SocketConduit 
                will take advantage of the timeout facilities provided there.

                Note that this is not intended to provide 'barrier' style 
                semantics for multi-threaded producer/consumer environments.

        ***********************************************************************/

        void wait ()
        {       
                get (1, false);
        }

        /***********************************************************************
        
                Append an array of data to this buffer, and flush to the
                conduit as necessary. Returns a chaining reference if all 
                data was written; throws an IOException indicating eof or 
                eob if not.

                This is often used in lieu of a Writer.

        ***********************************************************************/

        IBuffer append (void[] src)        
        {               
                uint size = src.length;

                if (size > writable)
                    // can we write externally?
                    if (conduit)
                       {
                       flush ();

                       // check for pathological case
                       if (size > capacity)
                          {
                          conduit.flush (src);
                          return this;
                          }
                       }
                    else
                       error (overflow);

                copy (src, size);
                return this;
        }

        /***********************************************************************
        
                Append another buffer to this one, and flush to the
                conduit as necessary. Returns a chaining reference if all 
                data was written; throws an IOException indicating eof or 
                eob if not.

                This is often used in lieu of a Writer.

        ***********************************************************************/

        IBuffer append (IBuffer other)        
        {               
                return append (other.toString);
        }

        /***********************************************************************
        
                Return a char[] slice of the buffer, from the current position 
                up to the limit of valid content. The content remains in the
                buffer for future extraction.

        ***********************************************************************/

        override char[] toString ()
        {       
                return cast(char[]) data[position..limit];
        }

        /***********************************************************************
        
                Skip ahead by the specified number of bytes, streaming from 
                the associated conduit as necessary.
        
                Can also reverse the read position by 'size' bytes, when size
                is negative. This may be used to support lookahead operations. 
                Note that a negative size will fail where there is not sufficient
                content available in the buffer (can't skip beyond the beginning).

                Returns true if successful, false otherwise.

        ***********************************************************************/

        bool skip (int size)
        {
                if (size < 0)
                   {
                   size = -size;
                   if (position >= size)
                      {
                      position -= size;
                      return true;
                      }
                   return false;
                   }
                return cast(bool) (get (size) !is null);
        }

        /***********************************************************************
        
                Support for tokenizing iterators. 
                
                Upon success, the delegate should return the byte-based 
                index of the consumed pattern (tail end of it). Failure
                to match a pattern should be indicated by returning an
                IConduit.Eof

                Each pattern is expected to be stripped of the delimiter.
                An end-of-file condition causes trailing content to be 
                placed into the token. Requests made beyond Eof result
                in empty matches (length == zero).

                Note that additional iterator and/or reader instances
                will stay in lockstep when bound to a common buffer.

                Returns true if a token was isolated, false otherwise.

        ***********************************************************************/

        bool next (uint delegate (void[]) scan)
        {
                while (read(scan) is IConduit.Eof)
                       if (conduit is null)
                          {
                          skip (readable);
                          return false;
                          }
                       else
                          {
                          // did we start at the beginning?
                          if (getPosition)
                              // nope - move partial token to start of buffer
                              compress ();
                          else
                             // no more space in the buffer?
                             if (writable is 0)
                                 error ("Token is too large to fit within buffer");

                          // read another chunk of data
                          if (fill(conduit) is IConduit.Eof)
                             {
                             skip (readable);
                             return false;
                             }
                          }
                return true;
        }

        /***********************************************************************
        
                Return count of readable bytes remaining in buffer. This is 
                calculated simply as limit() - position()

        ***********************************************************************/

        uint readable ()
        {
                return limit - position;
        }               

        /***********************************************************************
        
                Return count of writable bytes available in buffer. This is 
                calculated simply as capacity() - limit()

        ***********************************************************************/

        uint writable ()
        {
                return capacity - limit;
        }               

        /***********************************************************************

                Exposes the raw data buffer at the current write position, 
                The delegate is provided with a void[] representing space
                available within the buffer at the current write position.

                The delegate should return the appropriate number of bytes 
                if it writes valid content, or IConduit.Eof on error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        uint write (uint delegate (void[]) dg)
        {
                int count = dg (data [limit..capacity]);

                if (count != IConduit.Eof) 
                   {
                   limit += count;
                   assert (limit <= capacity);
                   }
                return count;
        }               

        /***********************************************************************

                Exposes the raw data buffer at the current read position. The
                delegate is provided with a void[] representing the available
                data, and should return zero to leave the current read position
                intact. 
                
                If the delegate consumes data, it should return the number of 
                bytes consumed; or IConduit.Eof to indicate an error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        uint read (uint delegate (void[]) dg)
        {
                
                int count = dg (data [position..limit]);
                
                if (count != IConduit.Eof)
                   {
                   position += count;
                   assert (position <= limit);
                   }
                return count;
        }               

        /***********************************************************************

                If we have some data left after an export, move it to 
                front-of-buffer and set position to be just after the 
                remains. This is for supporting certain conduits which 
                choose to write just the initial portion of a request.
                
                Limit is set to the amount of data remaining. Position 
                is always reset to zero.

        ***********************************************************************/

        IBuffer compress ()
        {
                uint r = readable ();

                if (position > 0 && r > 0)
                    // content may overlap ...
                    memcpy (&data[0], &data[position], r);

                position = 0;
                limit = r;
                return this;
        }               

        /***********************************************************************

                Try to fill the available buffer with content from the 
                specified conduit. In particular, we will never ask to 
                read less than 32 bytes. This permits conduit-filters 
                to operate within a known environment.

                Returns the number of bytes read, or Eof if there's no
                more data available. Where no conduit is attached, Eof 
                is always returned.
        
        ***********************************************************************/

        uint fill ()
        {
                if (conduit)
                    return fill (conduit);

                return IConduit.Eof;
        }

        /***********************************************************************

                Try to fill the available buffer with content from the 
                specified conduit. In particular, we will never ask to 
                read less than 32 bytes ~ this permits conduit-filters 
                to operate within a known environment. We also try to
                read as much as possible by clearing the buffer when 
                all current content has been eaten.

                Returns the number of bytes read, or Conduit.Eof
        
        ***********************************************************************/

        uint fill (IConduit conduit)
        {
                if (readable is 0)
                    clear();
                else
                   if (writable < 32)
                       if (compress().writable < 32)
                           error ("input buffer is too small");

                return write (&conduit.read);
        } 

        /***********************************************************************

                Make some room in the buffer. The requested space is simply
                an indicator of how much is desired. A subclass may or may
                not fulfill the request directly. 
                
                For example, the base-class simply performs a drain() on the 
                buffer.
                        
        ***********************************************************************/

        void makeRoom (uint space)
        {
                if (conduit)
                    drain ();
                else
                   error (overflow);
        }

        /***********************************************************************

                Write as much of the buffer that the associated conduit
                can consume.

                Returns the number of bytes written, or Conduit.Eof
        
        ***********************************************************************/

        uint drain ()
        {
                uint ret = read (&conduit.write);
                if (ret == conduit.Eof)
                    error (eofWrite);

                compress ();
                return ret;
        }

        /***********************************************************************
        
                flush the contents of this buffer to the related conduit.
                Throws an IOException on premature eof.

        ***********************************************************************/

        void flush ()
        {
                if (conduit)
                    if (conduit.flush (data [position..limit]))
                        clear();
                    else
                       error (eofWrite);
        } 

        /***********************************************************************
        
                Reset 'position' and 'limit' to zero. This effectively clears
                all content from the buffer.


        ***********************************************************************/

        IBuffer clear ()
        {
                position = limit = 0;
                return this;
        }               

        /***********************************************************************
        
                Truncate the buffer within its extend. Returns true if
                the new 'extent' is valid, false otherwise.

        ***********************************************************************/

        bool truncate (uint extent)
        {
                if (extent <= data.length)
                   {
                   limit = extent;
                   return true;
                   }
                return false;
        }               

        /***********************************************************************
        
                Returns the limit of readable content within this buffer.

                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint getLimit ()
        {
                return limit;
        }

        /***********************************************************************
        
                Returns the maximum capacity of this buffer

                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint getCapacity ()
        {
                return capacity;
        }

        /***********************************************************************
        
                Returns the current read-position within this buffer

                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint getPosition ()
        {
                return position;
        }

        /***********************************************************************
        
                Returns the conduit associated with this buffer. Returns 
                null if the buffer is purely memory based; that is, it's
                not backed by some external medium.

                Buffers do not require an external conduit to operate, but 
                it can be convenient to associate one. For example, methods
                fill() & drain() use it to import/export content as necessary.

        ***********************************************************************/

        IConduit getConduit ()
        {
                return conduit;
        }

        /***********************************************************************
        
                Sets the external conduit associated with this buffer.

                Buffers do not require an external conduit to operate, but 
                it can be convenient to associate one. For example, methods
                fill() & drain() use it to import/export content as necessary.

        ***********************************************************************/

        void setConduit (IConduit conduit)
        {
                this.conduit = conduit;
        }

        /***********************************************************************
                
                Return the entire backing array. Exposed for subclass usage 
                only

        ***********************************************************************/

        protected void[] getContent ()
        {
                return data;
        }

        /***********************************************************************
        
                Bulk copy of data from 'src'. The new content is made 
                available for reading. This is exposed for subclass use
                only 

        ***********************************************************************/

        protected void copy (void *src, uint size)
        {
                data[limit..limit+size] = src[0..size];
                limit += size;
        }
}
