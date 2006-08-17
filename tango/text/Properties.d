/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: May 2004      
        
        author:         Kris

*******************************************************************************/

module tango.text.Properties;

private import  tango.text.Text,
                tango.text.LineIterator;

private import  tango.io.Buffer,
                tango.io.FileConst,
                tango.io.FileConduit;

private import  tango.io.model.IConduit;

/*******************************************************************************
        
        Provides load facilities for a properties file. That is, a file
        or other medium containing lines of text with a name=value layout.

*******************************************************************************/

class Properties
{
        /***********************************************************************
        
                Load properties from the named file, and pass each of them
                to the provided delegate.

        ***********************************************************************/

        static void load (char[] filepath, void delegate (char[]name, char[] value) dg)
        {
                auto fc = new FileConduit (filepath, FileConduit.ReadExisting);
                scope (exit)
                       fc.close;
                
                load (fc, dg);
        }

        /***********************************************************************
        
                Load properties from the provided conduit, and pass them to
                the provided delegate.

        ***********************************************************************/

        static void load (IConduit conduit, void delegate (char[]name, char[] value) dg)
        {
                load (new Buffer(conduit), dg);
        }

        /***********************************************************************
        
                Load properties from the provided conduit, and pass them to
                the provided delegate.

        ***********************************************************************/

        static void load (IBuffer buffer, void delegate (char[]name, char[] value) dg)
        {
                // bind the input to a line tokenizer
                auto line = new LineIterator (buffer);

                // scan all lines
                while (line.next)
                      {
                      char[] text = line.trim.get;
                        
                      // comments require '#' as the first non-whitespace char 
                      if (text.length && (text[0] != '#'))
                         {
                         // find the '=' char
                         int i = Text.indexOf (text, '=');

                         // ignore if not found ...
                         if (i > 0)
                             dg (Text.trim (text[0..i]), Text.trim (text[i+1..text.length]));
                         }
                      }
        }

        /***********************************************************************
        
                Write properties to the provided filepath

        ***********************************************************************/

        static void save (char[] filepath, char[][char[]] properties)
        {
                auto fc = new FileConduit (filepath, FileConduit.WriteTruncate);
                scope (exit)
                       fc.close;
                save (fc, properties);
        }

        /***********************************************************************
        
                Write properties to the provided conduit

        ***********************************************************************/

        static void save (IConduit conduit, char[][char[]] properties)
        {
                save (new Buffer(conduit), properties);
        }

        /***********************************************************************
        
                Write properties to the provided buffer

        ***********************************************************************/

        static void save (IBuffer emit, char[][char[]] properties)
        {
                foreach (key, value; properties)
                         emit (key) (" = ") (value) (FileConst.NewlineString);
        }
}
