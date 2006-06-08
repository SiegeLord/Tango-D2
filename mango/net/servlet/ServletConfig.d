/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.ServletConfig;

private import  mango.net.servlet.Dictionary,
                mango.net.servlet.ServletContext;

/******************************************************************************

        Provides an equivalent to the Java class of the same name.

******************************************************************************/

class ServletConfig
{
        private ServletContext  context;
        private Dictionary      configuration;

        /***********************************************************************
        
                Construct an instance with the provided context. A dictionary
                is initialized in which to store configuration info.

        ***********************************************************************/

        this (ServletContext context)
        {
                this.context = context;
                configuration = new Dictionary();
        }
                
        /***********************************************************************
        
                Return the configuration dictionary 

        ***********************************************************************/

        Dictionary getConfiguration()
        {
                return configuration;
        }
    
        /***********************************************************************
        
                Return the context provided during construction

        ***********************************************************************/

        ServletContext getServletContext()
        {
                return context;
        }
}
