/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.CmdParser;

private import  tango.util.log.Log,
                tango.util.log.Config;

private import  tango.text.Arguments;

private import  tango.text.convert.Integer;

/******************************************************************************
        
        Extends the ArgParser to support/extract common arguments

******************************************************************************/

class CmdParser : Arguments
{
        Logger  log;
        ushort  port;
        uint    size;
        bool    help;

        /**********************************************************************

        **********************************************************************/

        this (char[] name)
        {
                log = Log.lookup (name);

                // default logging is info, not trace
                log.level = Level.Info;

                super ("/", "-", '=');
        }

        /**********************************************************************

        **********************************************************************/

        bool parse (char[][] args)
        {
                get('h').bind ({help = true;});
                get("log").bind ((char[] value){log.level(Log.convert(value));});
                get("port").bind ((char[] value){port = cast(ushort) atoi(value);});
                get("size").bind ((char[] value){size = atoi(value);});

                return super.parse (args);
        }
}
