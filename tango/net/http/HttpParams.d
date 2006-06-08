/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpParams;

private import  tango.io.model.IBuffer;

private import  tango.text.SimpleIterator;

private import  tango.net.http.HttpTokens;

/******************************************************************************

        Maintains a set of query parameters, parsed from an HTTP request.
        Use HttpMutableParams instead for output parameters.

        Note that these input params may have been encoded by the user-
        agent. Unfortunately there has been little consensus on what that
        encoding should be (especially regarding GET query-params). With
        luck, that will change to a consistent usage of UTF-8 within the 
        near future.

******************************************************************************/

class HttpParams : HttpTokens
{
        // tell compiler to used super.parse() also
        alias HttpTokens.parse parse;

        private SimpleIterator amp;

        /**********************************************************************
                
                Construct parameters by telling the HttpStack that
                name/value pairs are seperated by a '=' character.

        **********************************************************************/

        this ()
        {
                super ('=');

                // construct a line tokenizer for later usage
                amp = new SimpleIterator ("&");
        }

        /**********************************************************************
                
                Clone a source set of HttpParams

        **********************************************************************/

        this (HttpParams source)
        {
                super (source);
        }

        /**********************************************************************
                
                Clone this set of HttpParams

        **********************************************************************/

        HttpParams clone ()
        {
                return new HttpParams (this);
        }

        /**********************************************************************
                
                Read all query parameters. Everything is mapped rather 
                than being allocated & copied

        **********************************************************************/

        void parse (IBuffer input)
        {
                setParsed (true);
                amp.set (input);

                while (amp.next || amp.get.length)
                       stack.push (amp.get);
        }
}


/******************************************************************************

        HttpMutableParams are used for output purposes. This can be used
        to add a set of queries and then combine then into a text string
        using method write().

******************************************************************************/

class HttpMutableParams : HttpParams
{      
        /**********************************************************************
                
                Construct output params upon the provided IBuffer

        **********************************************************************/

        this (IBuffer output)
        {
                super();
                super.setOutputBuffer (output);
        }
        
        /**********************************************************************
                
                Clone a source set of HttpMutableParams

        **********************************************************************/

        this (HttpMutableParams source)
        {
                super (source);
        }

        /**********************************************************************
                
                Clone this set of HttpMutableParams

        **********************************************************************/

        HttpMutableParams clone ()
        {
                return new HttpMutableParams (this);
        }

        /**********************************************************************
                
                Add a name/value pair to the query list

        **********************************************************************/

        void add (char[] name, char[] value)
        {
                super.add (name, value);
        }

        /**********************************************************************
                
                Add a name/integer pair to the query list 

        **********************************************************************/

        void addInt (char[] name, int value)
        {
                super.addInt (name, value);
        }


        /**********************************************************************
                
                Add a name/date(long) pair to the query list

        **********************************************************************/

        void addDate (char[] name, ulong value)
        {
                super.addDate (name, value);
        }
}
