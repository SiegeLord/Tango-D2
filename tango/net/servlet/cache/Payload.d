/*******************************************************************************

        @file Payload.d
        
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

module tango.net.servlet.cache.Payload;

public import tango.net.servlet.cache.model.IPayload;

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


