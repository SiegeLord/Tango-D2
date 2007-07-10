/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         Kris

*******************************************************************************/

module tango.io.Conduit;

private import  tango.core.Exception;

private import  tango.io.model.IConduit;

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

class Conduit : IConduit, InputStream, OutputStream
{
        private InputStream             input_;
        private OutputStream            output_;
        private void delegate(bool)     notify_;

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

        abstract protected uint read (void[] dst);

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        abstract protected uint write (void [] src);

        /***********************************************************************

                default ctor assigns input and output streams to their
                initial value (this conduit)

        ***********************************************************************/

        this ()
        {
                input_ = this;
                output_ = this;

                // assign a default notification handler that does nothing
                notify_ = (bool){return;};
        }

        /***********************************************************************
        
                Return the host conduit. This is part of the Stream interface

        ***********************************************************************/

        final IConduit conduit()
        {
                return this;
        }
                            
        /***********************************************************************

                Is the conduit alive? Default behaviour returns true

        ***********************************************************************/

        bool isAlive ()
        {
                return true;
        }

        /***********************************************************************

                dump any output buffering

        ***********************************************************************/

        void flush ()
        {
        }

        /***********************************************************************

                clear any input buffering

        ***********************************************************************/

        void clear ()
        {
        }

        /***********************************************************************

                Close this conduit

        ***********************************************************************/

        void close ()
        {
        }

        /***********************************************************************

                Return the current input stream. The initial input stream
                is hosted by the conduit itself. Subsequent attachment of
                stream 'filters' will alter this value.

        ***********************************************************************/
        
        final InputStream input ()
        {
                return input_;
        }

        /***********************************************************************

                Return the current output stream. The initial output stream
                is hosted by the conduit itself. Subsequent attachment of
                stream 'filters' will alter this value.

        ***********************************************************************/
        
        final OutputStream output ()
        {
                return output_;
        }

        /***********************************************************************

                Replace the input stream and return the prior one. The
                return value should be used as the 'ancestor' attribute
                of attached filter, to be invoked appropriately during
                subsequent filter activity. However, it is entirely up
                to the intercepting stream to decide whether to follow
                that recommendation or not.

        ***********************************************************************/

        final InputStream attach (InputStream filter)
        {
                auto tmp = input_;
                input_ = filter;
                notify_ (true);
                return tmp;
        }

        /***********************************************************************

                Replace the output stream and return the prior one. The
                return value should be used as the 'ancestor' attribute
                of attached filter, to be invoked appropriately during
                subsequent filter activity. However, it is entirely up
                to the intercepting stream to decide whether to follow
                that recommendation or not.

        ***********************************************************************/

        final OutputStream attach (OutputStream filter)
        {
                auto tmp = output_;
                output_ = filter;
                notify_ (false);
                return tmp;
        }

        /***********************************************************************
        
                Attach a notification handler, to be invoked when a filter
                is added to the conduit. This is used in some very specific 
                cases, and should never need to support multiple clients.
                
        ***********************************************************************/

        final void notify (void delegate(bool) dg)
        {
                notify_ = dg;
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

*******************************************************************************/

class InputFilter : InputStream
{
        protected InputStream next;

        /***********************************************************************

        ***********************************************************************/

        abstract uint read (void[] dst);

        /***********************************************************************

        ***********************************************************************/

        this (InputStream stream)
        {
                next = stream.conduit.attach (this);
        }

        /***********************************************************************

        ***********************************************************************/

        IConduit conduit ()
        {
                return next.conduit;
        }

        /***********************************************************************

        ***********************************************************************/

        void clear ()
        {
                next.clear;
        }
}


/*******************************************************************************

*******************************************************************************/

class OutputFilter : OutputStream
{
        protected OutputStream next;

        /***********************************************************************

        ***********************************************************************/

        abstract uint write (void[] src);

        /***********************************************************************

        ***********************************************************************/

        this (OutputStream stream)
        {
                next = stream.conduit.attach (this);
        }

        /***********************************************************************

        ***********************************************************************/

        IConduit conduit ()
        {
                return next.conduit;
        }

        /***********************************************************************

        ***********************************************************************/

        void flush ()
        {
                next.flush;
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, or throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src)
        {
                return conduit.copy (src, this);
        }
}

