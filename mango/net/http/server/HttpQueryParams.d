/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.http.server.HttpQueryParams;

public  import  tango.net.http.HttpParams;
private import  tango.net.http.HttpTokens;

/******************************************************************************

        Maintains a set of HTTP query parameters. This is a specialization
        of HttpParams, with support for parameters without a '=' separator
        as would normally be expected.

******************************************************************************/

class HttpQueryParams : HttpParamsView
{
        /**********************************************************************
                
                Construct parameters by telling the TokenStack that
                name/value pairs are seperated by a '=' character.

        **********************************************************************/

        this ()
        {
                super ();
        }

        /**********************************************************************
                
                Clone a source set of HttpParams

        **********************************************************************/

        this (HttpParamsView source)
        {
                super (source);
        }

        /**********************************************************************

                overridable method to handle the case where a token does
                not have a separator. Apparently, this can happen in HTTP 
                usage

        **********************************************************************/

        protected bool handleMissingSeparator (char[] s, inout HttpToken element)
        {
                element.name = s;
                element.value = null;
                return true;
        }
}
