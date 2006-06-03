/*******************************************************************************

        @file HttpMessage.d
        
        Copyright (c) 2004 Kris Bell
        
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
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version, April 2004      
        @author         Kris


*******************************************************************************/

module mango.net.http.server.HttpMessage;

private import  tango.text.Text;

private import  tango.io.Buffer,
                tango.io.Exception;

private import  tango.io.model.IBuffer,
                tango.io.model.IWriter,
                tango.io.model.IConduit;

private import  tango.net.http.HttpHeaders;

private import  mango.net.http.server.model.IProviderBridge;


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
        private Buffer                  buffer;
        private IProviderBridge         bridge;
        private HttpMutableHeaders      headers;

        private char[]                  encoding,
                                        mimeType;

        /**********************************************************************

                Construct this HttpMessage using the specified HttpBridge.
                The bridge provides a gateway to both the server and 
                provider (servicer) instances.

        **********************************************************************/

        this (IProviderBridge bridge, IBuffer headerSpace)
        {
                this.bridge = bridge;

                // create a buffer for incoming requests
                buffer = new Buffer (HttpHeader.IOBufferSize);

                // reuse the input buffer for headers too?
                if (headerSpace is null)
                    headerSpace = buffer;

                // create instance of bidi headers 
                headers = new HttpMutableHeaders (headerSpace);
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

        protected final HttpMutableHeaders getHeader()
        {
                return headers;
        }

        /**********************************************************************
                
                Return the bridge used by the this message

        **********************************************************************/

        protected final IProviderBridge getBridge()
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
                   int semi = Text.indexOf (type, ';');
                   if (semi >= 0)
                      {
                      mimeType = Text.trim (type[0..semi]);
                      int cs = Text.indexOf (type, "charset=", semi);
                      if (cs >= 0)
                         {
                         cs += 8;
                         int end = Text.indexOf (type, ' ', cs);
                         if (end < 0)
                             end = type.length;
                         encoding = type[cs..end];
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



