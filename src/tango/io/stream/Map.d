/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

        Simple serialization for text-based name/value pairs

*******************************************************************************/

module tango.io.stream.Map;

private import tango.io.stream.Lines,
               tango.io.stream.Buffered;

private import Text = tango.text.Util;

private import tango.io.device.Conduit;

/*******************************************************************************

        Provides load facilities for a properties stream. That is, a file
        or other medium containing lines of text with a name=value layout

*******************************************************************************/

class MapInput(T) : Lines!(T)
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Load properties from the provided stream, via a foreach.

                We use an iterator to sweep text lines, and extract lValue
                and rValue pairs from each one, The expected file format is
                as follows:

                <pre>
                x = y
                abc = 123
                x.y.z = this is a single property

                # this is a comment line
                </pre>

                Note that the provided name and value are actually slices
                and should be copied if you intend to retain them (using
                name.dup and value.dup where appropriate)

        ***********************************************************************/

        final int opApply (int delegate(ref T[] name, ref T[] value) dg)
        {
                int ret;

                foreach (line; super)
                        {
                        auto text = Text.trim (line);

                        // comments require '#' as the first non-whitespace char
                        if (text.length && (text[0] != '#'))
                           {
                           // find the '=' char
                           auto i = Text.locate (text, cast(T) '=');

                           // ignore if not found ...
                           if (i < text.length)
                              {
                              auto name = Text.trim (text[0 .. i]);
                              auto value = Text.trim (text[i+1 .. $]);
                              if ((ret = dg (name, value)) != 0)
                                   break;
                              }
                           }
                        }
                return ret;
        }

        /***********************************************************************

                Load the input stream into an AA

        ***********************************************************************/

        final MapInput load (ref T[][T[]] properties)
        {
                foreach (name, value; this)
                         properties[name.dup] = value.dup;  
                return this;
        }
}


/*******************************************************************************

        Provides write facilities on a properties stream. That is, a file
        or other medium which will contain lines of text with a name=value 
        layout

*******************************************************************************/

class MapOutput(T) : OutputFilter
{
        private T[] eol;

        private const T[] prefix = "# ";
        private const T[] equals = " = ";
        version (Win32)
                 private const T[] NL = "\r\n";
        version (Posix)
                 private const T[] NL = "\n";

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, T[] newline = NL)
        {
                super (BufferedOutput.create (stream));
                eol = newline;
        }

        /***********************************************************************

                Append a newline to the provided stream

        ***********************************************************************/

        final MapOutput newline ()
        {
                sink.write (eol);
                return this;
        }

        /***********************************************************************

                Append a comment to the provided stream

        ***********************************************************************/

        final MapOutput comment (T[] text)
        {
                sink.write (prefix);
                sink.write (text);
                sink.write (eol);
                return this;
        }

        /***********************************************************************

                Append name & value to the provided stream

        ***********************************************************************/

        final MapOutput append (T[] name, T[] value)
        {
                sink.write (name);
                sink.write (equals);
                sink.write (value);
                sink.write (eol);
                return this;
        }

        /***********************************************************************

                Append AA properties to the provided stream

        ***********************************************************************/

        final MapOutput append (T[][T[]] properties)
        {
                foreach (key, value; properties)
                         append (key, value);
                return this;
        }
}



/*******************************************************************************
        
*******************************************************************************/
        
debug (UnitTest)
{
        import tango.io.Stdout;
        import tango.io.device.Array;
        
        unittest
        {
                auto buf = new Array(200);
                auto input = new MapInput!(char)(buf);
                auto output = new MapOutput!(char)(buf);

                char[][char[]] map;
                map["foo"] = "bar";
                map["foo2"] = "bar2";
                output.append(map).flush;

                map = map.init;
                input.load (map);
                assert (map["foo"] == "bar");
                assert (map["foo2"] == "bar2");
        }
}
