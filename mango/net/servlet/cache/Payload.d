/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.cache.Payload;

public import mango.net.servlet.cache.model.IPayload;

/******************************************************************************

        Base-class for entries placed into both the cache and cluster
        framework

******************************************************************************/

class Payload : IPayload
{
        private ulong time;

        /**********************************************************************

                Destroy this payload. Often used to return instances to a
                freelist, or otherwise release resources.

        **********************************************************************/

        void destroy ()
        {
        }

        /***********************************************************************

                Return the timestamp associated with this payload

        ***********************************************************************/

        ulong getTime ()
        {
                return time;
        }

        /***********************************************************************

                Set the timestamp of this payload

        ***********************************************************************/

        void setTime (ulong time)
        {
                this.time = time;
        }

        /**********************************************************************
        
                Recover the timestamp from the provided reader

        **********************************************************************/

        void read (IReader reader)
        {
                reader.get (time);
        }

        /**********************************************************************

                Emit our timestamp to the provided writer

        **********************************************************************/

        void write (IWriter writer)
        {
                writer.put (time);
        }

        /***********************************************************************

                Create a new instance of a payload, and populate it via
                read() using the specified reader

        ***********************************************************************/

        Object create (IReader reader)
        {
                Payload r = cast(Payload) create ();
                r.read (reader);
                return r;
        }

        /**********************************************************************

                Overridable create method that simply instantiates a 
                new instance. May be used to allocate subclassses from 
                a freelist

        **********************************************************************/

        Object create ()
        {
                return new Payload;
        }

        /**********************************************************************

                Return the guid for this payload. This should be unique
                per payload class, if said class is used in conjunction
                with the clustering facilities. Inspected by the Pickle
                utilitiy classes.
                
        **********************************************************************/

        char[] getGuid ()
        {
                return this.classinfo.name;
        }
}


