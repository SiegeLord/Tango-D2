/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpParams;

private import  tango.time.Time;

private import  tango.io.model.IConduit;

private import  tango.net.http.HttpTokens;

private import  tango.io.stream.Delimiters;

public  import  tango.net.http.model.HttpParamsView;

/******************************************************************************

        Maintains a set of query parameters, parsed from an HTTP request.
        Use HttpParams instead for output parameters.

        Note that these input params may have been encoded by the user-
        agent. Unfortunately there has been little consensus on what that
        encoding should be (especially regarding GET query-params). With
        luck, that will change to a consistent usage of UTF-8 within the 
        near future.

******************************************************************************/

class HttpParams : HttpTokens, HttpParamsView
{
        // tell compiler to expose super.parse() also
        alias HttpTokens.parse parse;
        alias HttpTokens.addInt addInt;

        private Delimiters!(char) amp;

        /**********************************************************************
                
                Construct parameters by telling the HttpStack that
                name/value pairs are seperated by a '=' character.

        **********************************************************************/

        this ()
        {
                super ('=');

                // construct a line tokenizer for later usage
                amp = new Delimiters!(char) ("&");
        }

        /**********************************************************************

                Return the number of headers

        **********************************************************************/

        uint size ()
        {
                return super.stack.size;
        }

        /**********************************************************************
                
                Read all query parameters. Everything is mapped rather 
                than being allocated & copied

        **********************************************************************/

        override void parse (InputBuffer input)
        {
                setParsed (true);
                amp.set (input);

                while (amp.next || amp.get().length)
                       stack.push (amp.get());
        }

        /**********************************************************************
                
                Add a name/value pair to the query list

        **********************************************************************/

        override void add (const(char)[] name, const(char)[] value)
        {
                super.add (name, value);
        }

        /**********************************************************************
                
                Add a name/integer pair to the query list 

        **********************************************************************/

        void addInt (const(char)[] name, int value)
        {
                super.addInt (name, value);
        }


        /**********************************************************************
                
                Add a name/date(long) pair to the query list

        **********************************************************************/

        override void addDate (const(char)[] name, Time value)
        {
                super.addDate (name, value);
        }

        /**********************************************************************
                
                Return the value of the provided header, or null if the
                header does not exist

        **********************************************************************/

        override const(char)[] get (const(char)[] name, const(char)[] ret = null)
        {
                return super.get (name, ret);
        }

        /**********************************************************************
                
                Return the integer value of the provided header, or the 
                provided default-value if the header does not exist

        **********************************************************************/

        override int getInt (const(char)[] name, int ret = -1)
        {
                return super.getInt (name, ret);
        }

        /**********************************************************************
                
                Return the date value of the provided header, or the 
                provided default-value if the header does not exist

        **********************************************************************/

        override Time getDate (const(char)[] name, Time ret = Time.epoch)
        {
                return super.getDate (name, ret);
        }


        /**********************************************************************

                Output the param list to the provided consumer

        **********************************************************************/

        override void produce (scope size_t delegate(const(void)[]) consume, const(char)[] eol=null)
        {
                return super.produce (consume, eol);
        }
}
