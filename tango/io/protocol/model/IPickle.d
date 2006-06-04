/*******************************************************************************

        @file IPickle.d
        
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


        @version        Initial version, March 2004      
        @author         Kris


*******************************************************************************/

module tango.io.protocol.model.IPickle;

public import tango.io.protocol.model.IReader,
              tango.io.protocol.model.IWriter;

/*******************************************************************************

        Interface for all serializable classes. Such classes are intended
        to be transported over a network, or be frozen in a file for later
        reconstruction. 

*******************************************************************************/

interface IPickle : IWritable, IReadable
{
        /***********************************************************************
        
                Identify this serializable class via a char[]. This should
                be (per class) unique within the domain. Use version numbers 
                or similar mechanism to isolate different implementations of
                the same class.

        ***********************************************************************/

        char[] getGuid ();
}


/*******************************************************************************

        Interface for all deserializable classes. Such classes either 
        implement the full concrete class instance or they act as a
        proxy of sorts, creating the true instance only when called 
        upon to do so. An IPickleProxy could perhaps take alternative 
        action when called upon to create an "old" or "unsupported" 
        class guid. The default behaviour is to throw an exception
        when an unknown guid is seen.

*******************************************************************************/

interface IPickleFactory
{
        /***********************************************************************
        
                Identify this serializable class via a char[]. This should
                be (per class) unique within the domain. Use version numbers 
                or similar mechanism to isolate different implementations of
                the same class.

        ***********************************************************************/

        char[] getGuid ();

        /***********************************************************************
        
                This defines the factory method. Each IPickleProxy object
                provides a factory for creating a deserialized instance.
                The factory is registered along with the appropriate guid.

        ***********************************************************************/

        Object create (IReader reader);
}

