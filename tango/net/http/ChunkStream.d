/*******************************************************************************

        copyright:      Copyright (c) Nov 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2007: Initial release

        author:         Kris

        Support for HTTP chunked I/O. 
        
        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html

*******************************************************************************/

module tango.net.http.ChunkStream;

private import  tango.io.Buffer,
                tango.io.device.Conduit;

private import  tango.text.stream.LineIterator;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        Prefix each block of data with its length (in hex digits) and add
        appropriate \r\n sequences. To commit the stream you'll need to use
        the terminate() function and optionally provide it with a callback 
        for writing trailing headers

*******************************************************************************/

class ChunkOutput : OutputFilter, Buffered
{
        private IBuffer output;

        /***********************************************************************

                Use a buffer belonging to our sibling, if one is available

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = Buffer.share(stream));
        }

        /***********************************************************************

                Buffered interface

        ***********************************************************************/

        IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Write a chunk to the output, prefixed and postfixed in a 
                manner consistent with the HTTP chunked transfer coding

        ***********************************************************************/

        final override uint write (void[] src)
        {
                char[8] tmp = void;
                
                output.append (Integer.format (tmp, src.length, "x"))
                      .append ("\r\n")
                      .append (src)
                      .append ("\r\n");
                return src.length;
        }

        /***********************************************************************

                Write a zero length chunk, trailing headers and a terminating 
                blank line

        ***********************************************************************/

        final void terminate (void delegate(IBuffer) headers = null)
        {
                output.append ("0\r\n");
                if (headers)
                    headers (output);
                output.append ("\r\n");
        }
}


/*******************************************************************************

        Parse hex digits, and use the resultant size to modulate requests 
        for incoming data. A chunk size of 0 terminates the stream, so to
        read any trailing headers you'll need to provide a delegate handler
        for receiving those

*******************************************************************************/

class ChunkInput : LineIterator!(char)
{
        private alias void delegate(char[] line) Headers;

        private Headers headers;
        private uint    available;

        /***********************************************************************

                Prime the available chunk size by reading and parsing the
                first available line

        ***********************************************************************/

        this (InputStream stream, Headers headers = null)
        {
                super (stream);
                available = nextChunk;
                this.headers = headers;
        }

        /***********************************************************************

                Read and parse another chunk size

        ***********************************************************************/

        private final uint nextChunk ()
        {
                char[] tmp;

                if ((tmp = super.next).ptr)
                     return cast(uint) Integer.parse (tmp, 16);
                return 0;
        }

        /***********************************************************************

                Read content based on a previously parsed chunk size

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                if (available is 0)
                   {
                   // terminated 0 - read headers and empty line, per rfc2616
                   char[] line;
                   while ((line = super.next).length)
                           if (headers)
                               headers (line);
                   return IConduit.Eof;
                   }
                        
                auto size = dst.length > available ? available : dst.length;
                auto read = super.read (dst [0 .. size]);
                
                // check for next chunk header
                if (read != IConduit.Eof && (available -= read) is 0)
                   {
                   // consume trailing \r\n
                   super.buffer.skip (2);
                   available = nextChunk ();
                   }
                
                return read;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (ChunkStream)
{
        import tango.io.Console;

        void main()
        {
                auto buf = new Buffer(40);
                auto chunk = new ChunkOutput (buf);
                chunk.write ("hello world");
                chunk.terminate;
                auto input = new ChunkInput (buf);
                Cout.stream.copy (input);
        }
}
