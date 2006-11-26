/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.model.IServletContext;


/******************************************************************************

        Provided equivalent functionality of the Java class by the same 
        name.

******************************************************************************/

abstract class IServletContext
{
        /***********************************************************************
        
                Return the name of this context.

        ***********************************************************************/

        abstract char[] getName ();
    
        /***********************************************************************
        
                Return the major version number.

        ***********************************************************************/

        abstract int getMajorVersion ();
    
        /***********************************************************************
        
                Return the minor number.

        ***********************************************************************/

        abstract int getMinorVersion ();

        /***********************************************************************
        
                Return the mime type for a given file extension. Returns
                null if the extension is not known.

        ***********************************************************************/

        abstract char[] getMimeType (char[] ext);

        /***********************************************************************
        
                Return a qualified version of the given path by prefixing
                the base-path

                Throws an IOException if the path is invalid, or there's a
                problem of some kind with the file.

        ***********************************************************************/

        abstract char[] getResourceAsPath (char[] path);

        /***********************************************************************
        
                Send an informational message to the logger subsystem

        ***********************************************************************/

        abstract IServletContext log (char[] msg);

        /***********************************************************************
        
                Send a error message to the logger subsystem

        ***********************************************************************/

        abstract IServletContext log (char[] msg, Object error);

        /***********************************************************************
        
                Return the identity of this server

        ***********************************************************************/

        abstract char[] getServerInfo ();

        /***********************************************************************
        
                Check the given path to see if it tries to subvert the
                base-path notion. Throws an IOException if anything dodgy
                is noted.

        ***********************************************************************/

        abstract IServletContext checkPath (char[] path);
}
