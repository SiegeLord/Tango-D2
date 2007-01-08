/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpWriter;

private import  tango.io.protocol.Writer,
                tango.io.protocol.PrintProtocol;

/******************************************************************************

        Not strictly necessary at this point, but will perhaps come in 
        handy at some future date.

******************************************************************************/

class HttpWriter : Writer
{
        alias newline cr;   
 
        public static const char[] eol = "\r\n";

        /***********************************************************************
        
        ***********************************************************************/

        this (IBuffer buffer)
        {
               super (new PrintProtocol(buffer));
        }


        IWriter newline()
        {
                return put(eol);
        }
}



