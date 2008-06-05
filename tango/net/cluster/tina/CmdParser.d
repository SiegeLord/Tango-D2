/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.CmdParser;

private import  tango.util.ArgParser;

private import  tango.text.convert.Integer;

private import  tango.util.log.Log,
                tango.util.log.Config;

/******************************************************************************
        
        Extends the ArgParser to support/extract common arguments

******************************************************************************/

class CmdParser : ArgParser
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
        }

        /**********************************************************************

        **********************************************************************/

        void parse (char[][] args)
        {
                static char[] strip (char[] value)
                {
                        if (value.length && (value[0] is '=' || value [0] is ':'))
                            value = value[1..$];
                        return value;
                }

                static int toInt (char[] value)
                {
                        return atoi (strip(value));
                }

                bind ("-", "h", {help = true;});

                bind ("-", "log", delegate (char[] value)
                                           {log.level(Log.convert(strip(value)));});

                bind ("-", "port", delegate (char[] value) 
                                            {port = cast(ushort) toInt (value);});

                bind ("-", "size", delegate (char[] value) 
                                            {size = toInt (value);});

                super.parse (args);
        }
}
