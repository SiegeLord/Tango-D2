/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
                        Outback release: December 2006
        
        author:         Kris

*******************************************************************************/

module tango.io.model.IConduit;

/*******************************************************************************

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

abstract class IConduit : ISelectable
{
        /***********************************************************************
        
                Declare the End-of-Flow identifer

        ***********************************************************************/

        enum : uint 
        {
                Eof = uint.max
        }

        /***********************************************************************

                Return the input stream

        ***********************************************************************/
        
        abstract InputStream input ();

        /***********************************************************************

                Return the output stream

        ***********************************************************************/
        
        abstract OutputStream output ();

        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        abstract uint bufferSize (); 
                     
        /***********************************************************************

                Is the conduit alive?

        ***********************************************************************/

        abstract bool isAlive ();

        /***********************************************************************
                
                Release external resources

        ***********************************************************************/

        abstract void close ();

        /***********************************************************************

                Models the ability to seek within a conduit

        ***********************************************************************/

        interface Seek
        {
                /***************************************************************
        
                        The anchor positions supported by seek()

                ***************************************************************/

                enum Anchor     {
                                Begin   = 0,
                                Current = 1,
                                End     = 2,
                                };

                /***************************************************************
                        
                        Return current conduit position (e.g. file position)
                
                ***************************************************************/

                ulong position ();

                /***************************************************************
                
                        Move the file position to the given offset from the 
                        provided anchor point, and return adjusted position.

                ***************************************************************/

                ulong seek (ulong offset, Anchor anchor = Anchor.Begin);
        }
}


/*******************************************************************************

        Describes how to make an IO entity usable with selectors
        
*******************************************************************************/

interface ISelectable
{      
        typedef int Handle = -1;        /// opaque OS file-handle        

        /***********************************************************************

                Models a handle-oriented device. 

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        Handle fileHandle ();
}


/*******************************************************************************
        

*******************************************************************************/

interface InputStream
{
        /***********************************************************************
        
                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        uint read (void[] dst);               
                             
        /***********************************************************************
        
                Fill the provided buffer. Returns the number of bytes 
                actually read, which will be less that dst.length when 
                Eof has been reached and zero thereafter

        ***********************************************************************/

        uint fill (void[] dst);               
                             
        /***********************************************************************
        
                Clear any buffered input

        ***********************************************************************/

        void flush ();               
}


/*******************************************************************************
        

*******************************************************************************/

interface OutputStream
{
        /***********************************************************************
        
                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        uint write (void[] dst);               
                             
        /***********************************************************************
        
                Flush provided content to the conduit. Will throw an 
                IOException where the operation can not be completed

        ***********************************************************************/

        void drain (void[] dst);               
                             
        /***********************************************************************
        
                Transfer the content of an InputStream to this OutputStream.
                Throws an IOException where the transfer can not be completed
        
        ***********************************************************************/

        void copy (InputStream input);               
                             
        /***********************************************************************
        
                write all buffered output to the attached conduit

        ***********************************************************************/

        void flush ();               
}
