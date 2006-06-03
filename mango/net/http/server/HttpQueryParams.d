/*******************************************************************************

        @file HttpQueryParams.d
        
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

module mango.net.http.server.HttpQueryParams;

public  import  tango.net.http.HttpParams;
private import  tango.net.http.HttpTokens;

/******************************************************************************

        Maintains a set of HTTP query parameters. This is a specialization
        of HttpParams, with support for parameters without a '=' separator
        as would normally be expected.

******************************************************************************/

class HttpQueryParams : HttpParams
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

        this (HttpParams source)
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
