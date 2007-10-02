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
        /***********************************************************************

                Propogate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }

        /***********************************************************************
        
                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        override synchronized uint read (void[] dst)
        {
                return host.read (dst);
        }             
                        
        /***********************************************************************
        
                Clear any buffered content

        ***********************************************************************/

        override synchronized void clear ()
        {
                host.clear;
        }
}


/*******************************************************************************

         A conduit filter that serializes access via synchronization 

*******************************************************************************/

class MutexOutput : OutputFilter
{
        /***********************************************************************

                Propogate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        override synchronized uint write (void[] src)
        {
                return host.write (src);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        override synchronized OutputStream copy (InputStream src)
        {
                return host.copy (src);
        }
                          
        /***********************************************************************

                Purge buffered content

        ***********************************************************************/

        override synchronized void flush ()
        {
                host.flush;
        }

        /***********************************************************************
        
                Commit output

        ***********************************************************************/

        override synchronized void commit ()
        {
                host.commit;
        }               
}


