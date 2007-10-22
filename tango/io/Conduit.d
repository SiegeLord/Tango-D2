/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         Kris

*******************************************************************************/

module tango.io.Conduit;

private import  tango.core.Exception;

public  import  tango.io.model.IConduit;

/*******************************************************************************

        Conduit abstract base-class, implementing interface IConduit.
        Only the conduit-specific read(), write(), fileHandle() and 
        bufferSize() need to be implemented for a concrete conduit 
        implementation. See FileConduit for an example.

        Conduits provide virtualized access to external content, and
        represent things like files or Internet connections. Conduits
        expose a pair of streams, are modelled by tango.io.model.IConduit, 
        and are implemented via classes such as FileConduit & SocketConduit. 

        Additional kinds of conduit are easy to construct: one either
        subclasses tango.io.Conduit, or implements tango.io.model.IConduit.
        A conduit typically reads and writes from/to an IBuffer in large
        chunks, typically the entire buffer. Alternatively, one can invoke
        input.read(dst[]) and/or output.write(src[]) directly.

*******************************************************************************/

class Conduit : IConduit
{
        private OutputStream    sink;
        private InputStream     source;

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        abstract uint bufferSize ();

        /***********************************************************************

                Models a handle-oriented device. We need to revisit this

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        abstract Handle fileHandle ();

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        abstract uint read (void[] dst);

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        abstract uint write (void [] src);

        /***********************************************************************

                Disconnect this conduit

        ***********************************************************************/

        abstract void detach ();

        /***********************************************************************
        
                Constructor to initialize the default sink & source

        ***********************************************************************/

        this ()
        {
                sink = this;
                source = this;
        }

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
                return source;
        }

        /***********************************************************************

                Return the current output stream

        ***********************************************************************/
        
        final OutputStream output ()
        {
                return sink;
        }

        /***********************************************************************

                Throw an IOException, with the provided message

        ***********************************************************************/

        final void exception (char[] msg)
        {
                throw new IOException (msg);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        final OutputStream copy (InputStream src)
        {
                return copy (src, this);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                the dst OutputStream, or throws IOException on failure.

        ***********************************************************************/

        final OutputStream copy (InputStream src, OutputStream dst)
        {
                uint i;
                auto tmp = new byte [dst.conduit.bufferSize];

                while ((i = src.read(tmp)) != IConduit.Eof)
                      {
                      auto p = tmp.ptr;
                      for (uint j; i > 0; i -= j, p += j)
                           if ((j = dst.write (p[0..i])) is IConduit.Eof)
                                exception ("OutputStream.copy :: Eof while copying");
                      }
                
                delete tmp;
                return dst;
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
                requested in dst

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
                be less than the quantity provided

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

                Close the output

        ***********************************************************************/

        void close ()
        {
                host.close;
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, or throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src)
        {
                host.copy (src);
                return this;
        }
}

