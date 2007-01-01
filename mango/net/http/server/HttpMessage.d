/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpMessage;

private import  Text = tango.text.Goodies;

private import  tango.io.Buffer,
                tango.io.Exception;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.io.protocol.model.IWriter;

private import  tango.net.http.HttpHeaders;

private import  mango.net.http.server.ServiceBridge;


/******************************************************************************

        Exception thrown when the http environment is in an invalid state.
        This can occur if, for example, a program attempts to update the 
        output headers after some data has already been written back to
        the user-agent.

******************************************************************************/

class InvalidStateException : IOException
{
        /**********************************************************************

                Construct this exception with the provided text string
        
        **********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}


/******************************************************************************

        The basic HTTP message. Acts as a base-class for HttpRequest and
        HttpResponse. 

******************************************************************************/

class HttpMessage : IWritable
{
        private Buffer          buffer;
        private ServiceBridge   bridge;
        private HttpHeaders     headers;

        private char[]          encoding,
                                mimeType;

        /**********************************************************************

                Construct this HttpMessage using the specified HttpBridge.
                The bridge provides a gateway to both the server and 
                provider (servicer) instances.

        **********************************************************************/

        this (ServiceBridge bridge, IBuffer headerSpace)
        {
                this.bridge = bridge;

                // create a buffer for incoming requests
                buffer = new Buffer (HttpHeader.IOBufferSize);

                // reuse the input buffer for headers too?
                if (headerSpace is null)
                    headerSpace = buffer;

                // create instance of bidi headers 
                headers = new HttpHeaders (headerSpace);
        }

        /**********************************************************************

                Reset this message

        **********************************************************************/

        void reset()
        {
                encoding = null;
                mimeType = null;
                headers.reset();
        }

        /**********************************************************************

                Set the IConduit used by this message; typically this is
                the SocketConduit instantiated in response to a connection
                request.

                Given that the HttpMessage remains live (on a per-thread
                basis), this method will be called for each connection
                request.

        **********************************************************************/

        void setConduit (IConduit conduit)
        {
                buffer.setConduit (conduit);
                buffer.clear();
        }

        /**********************************************************************

                Return the IConduit in use

        **********************************************************************/

        protected final IConduit getConduit ()
        {
                return buffer.getConduit();
        }

        /**********************************************************************

                Return the buffer bound to our conduit

        **********************************************************************/

        protected final IBuffer getBuffer()
        {
                return buffer;
        }

        /**********************************************************************

                Return the HttpHeaders wrapper

        **********************************************************************/

        protected final HttpHeaders getHeader()
        {
                return headers;
        }

        /**********************************************************************
                
                Return the bridge used by the this message

        **********************************************************************/

        protected final ServiceBridge getBridge()
        {
                return bridge;
        }

        /**********************************************************************

                Return the encoding string 

        **********************************************************************/

        char[] getEncoding()
        {
                return encoding;
        }

        /**********************************************************************

                Return the mime-type in use

        **********************************************************************/

        char[] getMimeType()
        {
                return mimeType;
        }

        /**********************************************************************

                Set the content-type header, and parse it for encoding and
                mime-tpye information.

        **********************************************************************/

        void setContentType (char[] type)
        {
                headers.add (HttpHeader.ContentType, type);
                setMimeAndEncoding (type);
        }

        /**********************************************************************

                Return the content-type from the headers.

        **********************************************************************/

        char[] getContentType()
        {
                return Text.trim (headers.get (HttpHeader.ContentType));
        }

        /**********************************************************************

                Parse a text string looking for encoding and mime information

        **********************************************************************/

        protected void setMimeAndEncoding (char[] type)
        {
                encoding = null;
                mimeType = type;

                if (type)
                   {
                   auto semi = Text.find (type, ';');
                   if (semi)
                      {
                      --semi;
                      mimeType = Text.trim (type[0..semi]);
                      auto cs = Text.search (type, "charset=", semi);
                      if (cs)
                         {
                         cs += 7;
                         auto end = Text.find (type, ' ', cs);
                         encoding = end ? type[cs..end-1] : type[cs..$];
                         }
                      }
                   }
        }

        /**********************************************************************

                Output our headers to the provided IWriter

        **********************************************************************/

        void write (IWriter writer)
        {
                headers.write (writer);
        }
}
