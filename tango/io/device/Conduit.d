/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release

        author:         Kris

*******************************************************************************/

module tango.io.device.Conduit;

private import  tango.core.Exception;

public  import  tango.io.model.IConduit;

/*******************************************************************************

        Conduit abstract base-class, implementing interface IConduit.
        Only the conduit-specific read(), write(), and 
        bufferSize() need to be implemented for a concrete conduit 
        implementation. See FileConduit for an example.

        Conduits provide virtualized access to external content, and
        represent things like files or Internet connections. Conduits
        expose a pair of streams, are modelled by tango.io.model.IConduit, 
        and are implemented via classes such as FileConduit & SocketConduit. 

        Additional kinds of conduit are easy to construct: one either
        subclasses tango.io.device.Conduit, or implements tango.io.model.IConduit.
        A conduit typically reads and writes from/to an IBuffer in large
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

        abstract uint bufferSize ();

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst. Eof is returned whenever an end-of-flow 
                condition arises.

        ***********************************************************************/

        abstract uint read (void[] dst);

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Eof is returned when 
                an end-of-flow condition arises.

        ***********************************************************************/

        abstract uint write (void [] src);

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

        final IConduit conduit()
        {
                return this;
        }
                            
        /***********************************************************************

                clear any buffered input

        ***********************************************************************/

        InputStream clear () {return this;}

        /***********************************************************************

                Write buffered output

        ***********************************************************************/

        OutputStream flush () {return this;}

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

                Return the current input stream 
                 
        ***********************************************************************/
        
        final InputStream input ()
        {
                return this;
        }

        /***********************************************************************

                Return the current output stream

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

        final OutputStream copy (InputStream src)
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

        final void[] load (void[] dst = null)
        {
                return load (this, dst);
        }

        /***********************************************************************


                Load the bits from a stream, and return them all in an
                array. The dst array can be provided as an option, which
                will be expanded as necessary to consume the input.

                Returns an array representing the content, and throws
                IOException on error
                
        ***********************************************************************/

        static void[] load (InputStream src, void[] dst = null)
        {
                auto index = 0;
                auto chunk = 256;
                
                do {
                   if (dst.length - index < chunk)
                       dst.length = dst.length + (chunk * 2);

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
                byte[8192]      tmp;
                size_t          done;

                while (max)
                      {
                      auto len = max;
                      if (len > tmp.length)
                          len = tmp.length;

                      if ((len = src.read(tmp[0 .. len])) is IConduit.Eof)
                           max = 0;
                      else
                         {
                         max -= len;
                         done += len;
                         auto p = tmp.ptr;
                         for (uint j; len > 0; len -= j, p += j)
                              if ((j = dst.write (p[0 .. len])) is IConduit.Eof)
                                   dst.conduit.error ("Conduit.copy :: Eof while writing to: "~dst.conduit.toString);
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
        protected InputStream host;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (InputStream host)
        {
                assert (host, "input stream host cannot be null");
                this.host = host;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return host.conduit;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst. Eof is returned whenever an end-of-flow 
                condition arises.

        ***********************************************************************/

        uint read (void[] dst)
        {
                return host.read (dst);
        }

        /***********************************************************************

                Clear any buffered content

        ***********************************************************************/

        InputStream clear ()
        {
                host.clear;
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
                return Conduit.load (this, dst);
        }

        /***********************************************************************

                Close the input

        ***********************************************************************/

        void close ()
        {
                host.close;
        }
}


/*******************************************************************************

         Base class for output stream filtering  

*******************************************************************************/

class OutputFilter : OutputStream
{
        protected OutputStream host;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (OutputStream host)
        {
                assert (host, "output stream host cannot be null");
                this.host = host;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return host.conduit;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Eof is returned when 
                an end-of-flow condition arises.

        ***********************************************************************/

        uint write (void[] src)
        {
                return host.write (src);
        }

        /***********************************************************************

                Emit/purge buffered content

        ***********************************************************************/

        OutputStream flush ()
        {
                host.flush;
                return this;
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

                Close the output

        ***********************************************************************/

        void close ()
        {
                host.close;
        }
}



