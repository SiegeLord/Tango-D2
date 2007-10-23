/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.MutexStream;

private import tango.io.Conduit;

/*******************************************************************************

        A stream filter that serializes access via synchronization     

*******************************************************************************/

class MutexInput : InputFilter
{
        private Object mutex;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, Object mutex=null)
        {
                super (stream);
                if (mutex is null)
                    mutex = this;
                this.mutex = mutex;
        }

        /***********************************************************************
        
                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        override uint read (void[] dst)
        {
                synchronized (mutex)
                              return host.read (dst);
        }             
                        
        /***********************************************************************
        
                Clear any buffered content

        ***********************************************************************/

        override InputStream clear ()
        {
                synchronized (mutex)
                              host.clear;
                return this;
        }

        /***********************************************************************
        
                Close input

        ***********************************************************************/

        override void close ()
        {
                synchronized (mutex)
                              host.close;
        }               
}


/*******************************************************************************

         A stream filter that serializes access via synchronization 

*******************************************************************************/

class MutexOutput : OutputFilter
{
        private Object mutex;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, Object mutex=null)
        {
                super (stream);
                if (mutex is null)
                    mutex = this;
                this.mutex = mutex;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        override uint write (void[] src)
        {
                synchronized (mutex)
                              return host.write (src);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        override OutputStream copy (InputStream src)
        {
                synchronized (mutex)
                              host.copy (src);
                return this;
        }
                          
        /***********************************************************************

                Purge buffered content

        ***********************************************************************/

        override OutputStream flush ()
        {
                synchronized (mutex)
                              host.flush;
                return this;
        }

        /***********************************************************************
        
                Close output

        ***********************************************************************/

        override void close ()
        {
                synchronized (mutex)
                              host.close;
        }               
}


