/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpReader;

private import  tango.io.protocol.Reader;

private import  tango.convert.Type;

private import  tango.io.model.IBuffer;

/******************************************************************************

        There's no real need at this time to provide an http-specific 
        reader. This is just for future growth.

******************************************************************************/

class HttpReader : Reader
{
        /***********************************************************************
        
        ***********************************************************************/

        this (IBuffer buffer)
        {
               super (buffer);
        }
}
