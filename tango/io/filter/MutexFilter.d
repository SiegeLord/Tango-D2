/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2007

        author:         Kris

*******************************************************************************/

module tango.io.filter.MutexFilter;

private import tango.io.Conduit;

private import tango.io.model.IConduit;

/*******************************************************************************

        A conduit filter that serializes access via synchronization     

*******************************************************************************/

class MutexInput : InputFilter
{
        private Object mutex;

        /***********************************************************************

                Propogate ctor to superclass

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

        override void clear ()
        {
                synchronized (mutex)
                              host.clear;
        }
}


/*******************************************************************************

         A conduit filter that serializes access via synchronization 

*******************************************************************************/

class MutexOutput : OutputFilter
{
        private Object mutex;

        /***********************************************************************

                Propogate ctor to superclass

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
                              return host.copy (src);
        }
                          
        /***********************************************************************

                Purge buffered content

        ***********************************************************************/

        override void flush ()
        {
                synchronized (mutex)
                              host.flush;
        }

        /***********************************************************************
        
                Commit output

        ***********************************************************************/

        override void commit ()
        {
                synchronized (mutex)
                              host.commit;
        }               
}


