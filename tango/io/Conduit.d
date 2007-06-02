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

class Conduit : private AbstractOutputStream, IConduit, InputStream
{
        private InputStream  input_;
        private OutputStream output_;

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


        ***********************************************************************/

        this ()
        {
                input_ = this;
                output_ = this;
        }

        /***********************************************************************

                Return the input stream

        ***********************************************************************/
        
        final InputStream input ()
        {
                return input_;
        }

        /***********************************************************************

                Return the output stream

        ***********************************************************************/
        
        final OutputStream output ()
        {
                return output_;
        }

        /***********************************************************************

        ***********************************************************************/

        final InputStream attach (InputStream filter)
        {
                auto tmp = input_;
                input_ = filter;
                return tmp;
        }

        /***********************************************************************

        ***********************************************************************/

        final OutputStream attach (OutputStream filter)
        {
                auto tmp = output_;
                output_ = filter;
                return tmp;
        }

        /***********************************************************************
        
                Return the host conduit

        ***********************************************************************/

        final IConduit conduit()
        {
                return this;
        }
                            
        /***********************************************************************

                Is the conduit alive?

        ***********************************************************************/

        bool isAlive ()
        {
                return true;
        }

        /***********************************************************************

                Close this conduit

        ***********************************************************************/

        void close ()
        {
        }

        /***********************************************************************

        ***********************************************************************/

        void exception (char[] msg)
        {
                throw new IOException (msg);
        }
}


/*******************************************************************************

*******************************************************************************/

abstract class AbstractOutputStream : OutputStream
{
        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        final OutputStream copy (InputStream src)
        {
                auto buffer = new byte[conduit.bufferSize];
                auto p = buffer.ptr;

                uint i;
                while ((i = src.read (buffer)) != IConduit.Eof)
                        for (uint j; i > 0; i -= j, p += j)
                             if ((j = write (p[0..i])) is IConduit.Eof)
                                  conduit.exception ("OutputStream.copy :: Eof while copying");
                
                delete buffer;
                return this;
        }

        /***********************************************************************

                dump any buffered content

        ***********************************************************************/

        void flush ()
        {
        }
}

