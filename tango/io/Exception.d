/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

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

