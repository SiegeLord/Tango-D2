/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release

        author:         Kris

*******************************************************************************/

module tango.io.device.Conduit;

private import tango.core.Exception;

public  import tango.io.model.IConduit;

/*******************************************************************************

        Conduit abstract base-class, implementing interface IConduit.
        Only the conduit-specific read(), write(), detach() and 
        bufferSize() need to be implemented for a concrete conduit 
        implementation. See File for an example.

        Conduits provide virtualized access to external content, and
        represent things like files or Internet connections. Conduits
        expose a pair of streams, are modelled by tango.io.model.IConduit, 
        and are implemented via classes such as File & SocketConduit. 

        Additional kinds of conduit are easy to construct: one either
        subclasses tango.io.device.Conduit, or implements tango.io.model.IConduit.
        A conduit typically reads and writes from/to a Buffer in large
        chunks, typically the entire buffer. Alternatively, one can invoke
        input.read(dst[]) and/or output.write(src[]) directly.

*******************************************************************************/

class Conduit : IConduit
{
        /***********************************************************************
        
                Return the name of this conduit

        ***********************************************************************/

        abstract char[] toString (); 
                     
        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        abstract size_t bufferSize ();

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst. Eof is returned whenever an end-of-flow 
                condition arises.

        ***********************************************************************/

        abstract size_t read (void[] dst);

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Eof is returned when 
                an end-of-flow condition arises.

        ***********************************************************************/

        abstract size_t write (void [] src);

        /***********************************************************************

                Disconnect this conduit

        ***********************************************************************/

        abstract void detach ();

        /***********************************************************************

                Is the conduit alive? Default behaviour returns true

        ***********************************************************************/

        bool isAlive ()
        {
                return true;
        }

        /***********************************************************************
        
                Return the host. This is part of the Stream interface

        ***********************************************************************/

        final IConduit conduit ()
        {
                return this;
        }
                            
        /***********************************************************************

                clear any buffered input

        ***********************************************************************/

        InputStream clear () 
        {
                return this;
        }

        /***********************************************************************

                Emit buffered output

        ***********************************************************************/

        OutputStream flush () 
        {
                return this;
        }

        /***********************************************************************

                Close this conduit
                
                Remarks:
                Both input and output are detached, and are no longer usable

        ***********************************************************************/

        final void close ()
        {
                this.detach;
        }

        /***********************************************************************

                Return the input stream 

        ***********************************************************************/
        
        final InputStream input ()
        {
                return this;
        }

        /***********************************************************************

                Return the output stream

        ***********************************************************************/
        
        final OutputStream output ()
        {
                return this;
        }

        /***********************************************************************

                Throw an IOException, with the provided message

        ***********************************************************************/

        final void error (char[] msg)
        {
                throw new IOException (msg);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                the dst OutputStream, or throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src)
        {
                transfer (src, this);
                return this;
        }

        /***********************************************************************

                Load the bits from a stream, and return them all in an
                array. The dst array can be provided as an option, which
                will be expanded as necessary to consume the input.

                Returns an array representing the content, and throws
                IOException on error
                
        ***********************************************************************/

        void[] load (void[] dst = null)
        {
                return load (this, dst);
        }

        /***********************************************************************
        
                Seek on this stream. Source conduits that don't support
                seeking will throw an IOException

        ***********************************************************************/

        long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                error (this.toString ~ " does not support seek requests");
                return 0;
        }

        /***********************************************************************

                Load the bits from a stream, and return them all in an
                array. The dst array can be provided as an option, which
                will be expanded as necessary to consume input.

                Returns an array representing the content, and throws
                IOException on error
                
        ***********************************************************************/

        static void[] load (InputStream src, void[] dst = null)
        {
                auto index = 0;
                auto chunk = 8192;
                
                do {
                   if (dst.length - index < 1024)
                       dst.length = chunk + dst.length + dst.length / 2;

                   chunk = src.read (dst[index .. $]);
                   index += chunk;
                   } while (chunk != Eof)

                return dst [0 .. index - chunk];
        }

        /***********************************************************************
                
                Low-level data transfer, where max represents the maximum
                number of bytes to transfer, and tmp represents space for
                buffering the transfer. Throws IOException on failure.

        ***********************************************************************/

        static size_t transfer (InputStream src, OutputStream dst, size_t max=size_t.max)
        {
                byte[8192] tmp;
                size_t     done;

                while (max)
                      {
                      auto len = max;
                      if (len > tmp.length)
                          len = tmp.length;

                      if ((len = src.read(tmp[0 .. len])) is Eof)
                           max = 0;
                      else
                         {
                         max -= len;
                         done += len;
                         auto p = tmp.ptr;
                         for (auto j=0; len > 0; len -= j, p += j)
                              if ((j = dst.write (p[0 .. len])) is Eof)
                                   dst.conduit.error ("Conduit.copy :: Eof while writing to: "~
                                                       dst.conduit.toString);
                         }
                      }

                return done;
        }
}


/*******************************************************************************

        Base class for input stream filtering

*******************************************************************************/

class InputFilter : InputStream
{
        protected InputStream source;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (InputStream source)
        {
                assert (source, "input stream source cannot be null");
                this.source = source;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return source.conduit;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst. Eof is returned whenever an end-of-flow 
                condition arises.

        ***********************************************************************/

        size_t read (void[] dst)
        {
                return source.read (dst);
        }

        /***********************************************************************

                Load the bits from a stream, and return them all in an
                array. The dst array can be provided as an option, which
                will be expanded as necessary to consume the input.

                Returns an array representing the content, and throws
                IOException on error
                              
        ***********************************************************************/

        void[] load (void[] dst = null)
        {
                return Conduit.load (this, dst);
        }

        /***********************************************************************

                Clear any buffered content

        ***********************************************************************/

        InputStream clear ()
        {
                source.clear;
                return this;
        }

        /***********************************************************************
        
                Seek on this stream. Target conduits that don't support
                seeking will throw an IOException

        ***********************************************************************/

        long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                return source.seek (offset, anchor);
        }

        /***********************************************************************

                Return the upstream host of this filter
                        
        ***********************************************************************/

        InputStream input ()
        {
                return source;
        }            

        /***********************************************************************

                Close the input

        ***********************************************************************/

        void close ()
        {
                source.close;
        }
}


/*******************************************************************************

         Base class for output stream filtering  

*******************************************************************************/

class OutputFilter : OutputStream
{
        protected OutputStream sink;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (OutputStream sink)
        {
                assert (sink, "output stream cannot be null");
                this.sink = sink;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return sink.conduit;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Eof is returned when 
                an end-of-flow condition arises.

        ***********************************************************************/

        size_t write (void[] src)
        {
                return sink.write (src);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, or throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src)
        {
                Conduit.transfer (src, this);
                return this;
        }

        /***********************************************************************

                Emit/purge buffered content

        ***********************************************************************/

        OutputStream flush ()
        {
                sink.flush;
                return this;
        }

        /***********************************************************************
        
                Seek on this stream. Target conduits that don't support
                seeking will throw an IOException

        ***********************************************************************/

        long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                return sink.seek (offset, anchor);
        }

        /***********************************************************************
        
                Return the upstream host of this filter
                        
        ***********************************************************************/

        OutputStream output ()
        {
                return sink;
        }              

        /***********************************************************************

                Close the output

        ***********************************************************************/

        void close ()
        {
                sink.close;
        }
}

