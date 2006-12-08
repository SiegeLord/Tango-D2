/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.Exception;

/*******************************************************************************

        The basic exception thrown by the tango.io package. One should
        try to ensure that all Tango exceptions related to IO are derived
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

