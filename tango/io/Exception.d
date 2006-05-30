/*******************************************************************************

        @file Exception.d
        
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

module tango.io.Exception;

/*******************************************************************************

        The basic exception thrown by the tango.io package. One should
        try to ensure that all Mango exceptions related to IO are derived
        from this one.

*******************************************************************************/

class IOException : Exception
{
        /***********************************************************************
        
                Construct exception with the provided text string

        ***********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}

/*******************************************************************************

        This exception is thrown by Readers whenever the file content is
        terminated unexpectedly. A Writer throws the exception when it
        fails to append data to an externl conduit.

*******************************************************************************/

class EofException : IOException
{
        /***********************************************************************
        
                Construct exception with the provided text string

        ***********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}

/*******************************************************************************

        These exceptions are thrown by the Token subsystem, typically for
        invalid data formatting or other content related issues.

*******************************************************************************/

class TokenException : IOException
{
        /***********************************************************************
        
                Construct exception with the provided text string

        ***********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}

/*******************************************************************************

        PickleException is thrown when the PickleRegistry encounters a 
        problem during proxy registration, or when it sees an unregistered
        guid.

*******************************************************************************/

class PickleException : IOException
{
        /***********************************************************************
        
                Construct exception with the provided text string

        ***********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }        
}

