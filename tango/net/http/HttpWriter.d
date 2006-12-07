/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris
                        h3r3tic

*******************************************************************************/

module tango.net.http.HttpWriter;

private import  tango.io.protocol.DisplayWriter;

/******************************************************************************

        Not strictly necessary at this point, but will perhaps come in 
        handy at some future date.

******************************************************************************/

class HttpWriter : DisplayWriter
{
        alias newline cr;   
 
        public static const char[] eol = "\r\n";

        /***********************************************************************
        
        ***********************************************************************/

        this (IBuffer buffer)
        {
               super (buffer);
        }


        IWriter newline()
        {
                return put(eol);
        }
}



