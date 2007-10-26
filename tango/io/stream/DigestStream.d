/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.DigestStream;

private import tango.io.Conduit;

private import tango.io.digest.Digest;

/*******************************************************************************

        Buffers the flow of data from a upstream input. A downstream 
        neighbour can locate and use this buffer instead of creating 
        another instance of their own. 

        (note that upstream is closer to the source, and downstream is
        further away)

*******************************************************************************/

class DigestInput : InputFilter
{
        private Digest digest;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, Digest digest)
        {
                super (stream);
                this.digest = digest;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        override uint read (void[] dst)
        {
                auto len = host.read (dst);
                if (len != IConduit.Eof)
                    digest.update (dst [0..len]);
                return len;
        }

        /********************************************************************

               Computes the digest and resets the state

               Params:
                   buffer = a buffer can be supplied for the digest to be
                            written to

               Remarks:
                   If the buffer is not large enough to hold the
                   digest, a new buffer is allocated and returned.
                   The algorithm state is always reset after a call to
                   binaryDigest. Use the digestSize method to find out how
                   large the buffer has to be.
                   
        *********************************************************************/
    
        ubyte[] binaryDigest (ubyte[] buffer = null)
        {
                return digest.binaryDigest(buffer);
        }

        /*********************************************************************
               
               Computes the digest as a hex string and resets the state
               
               Params:
                   buffer = a buffer can be supplied in which the digest
                            will be written. It needs to be able to hold
                            2 * digestSize chars
            
               Remarks:
                    If the buffer is not large enough to hold the hex digest,
                    a new buffer is allocated and returned. The algorithm
                    state is always reset after a call to hexDigest.
                    
        *********************************************************************/
        
        char[] hexDigest (char[] buffer = null) 
        {
                return digest.hexDigest(buffer);
        }
}


/*******************************************************************************
        
        Buffers the flow of data from a upstream output. A downstream 
        neighbour can locate and use this buffer instead of creating 
        another instance of their own.

        (note that upstream is closer to the source, and downstream is
        further away)

        Don't forget to flush() buffered content before closing.

*******************************************************************************/

class DigestOutput : OutputFilter
{
        private Digest digest;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, Digest digest)
        {
                super (stream);
                this.digest = digest;
        }

        /***********************************************************************
        
                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        override uint write (void[] src)
        {
                auto len = host.write (src);
                if (len != IConduit.Eof)
                    digest.update (src[0..len]);
                return len;
        }

        /********************************************************************

               Computes the digest and resets the state

               Params:
                   buffer = a buffer can be supplied for the digest to be
                            written to

               Remarks:
                   If the buffer is not large enough to hold the
                   digest, a new buffer is allocated and returned.
                   The algorithm state is always reset after a call to
                   binaryDigest. Use the digestSize method to find out how
                   large the buffer has to be.
                   
        *********************************************************************/
    
        ubyte[] binaryDigest (ubyte[] buffer = null)
        {
                return digest.binaryDigest(buffer);
        }

        /*********************************************************************
               
               Computes the digest as a hex string and resets the state
               
               Params:
                   buffer = a buffer can be supplied in which the digest
                            will be written. It needs to be able to hold
                            2 * digestSize chars
            
               Remarks:
                    If the buffer is not large enough to hold the hex digest,
                    a new buffer is allocated and returned. The algorithm
                    state is always reset after a call to hexDigest.
                    
        *********************************************************************/
        
        char[] hexDigest (char[] buffer = null) 
        {
                return digest.hexDigest(buffer);
        }
}


debug (DigestStream)
{
        import tango.io.Stdout;
        import tango.io.digest.Md5;
        import tango.io.stream.FileStream;

        void main()
        {
                auto output = new DigestOutput(new FileOutput("foo.d"), new Md5);
                output.copy (new FileInput("digeststream.d"));
                Stdout.formatln ("hex digest:{}", output.hexDigest);
        }
}
