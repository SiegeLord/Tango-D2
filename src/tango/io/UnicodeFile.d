/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005      
        
        author:         Kris

*******************************************************************************/

module tango.io.UnicodeFile;

private import tango.io.device.File;

public  import tango.text.convert.UnicodeBom;

/*******************************************************************************

        Read and write unicode files

        For our purposes, unicode files are an encoding of textual material.
        The goal of this module is to interface that external-encoding with
        a programmer-defined internal-encoding. This internal encoding is
        declared via the template argument T, whilst the external encoding
        is either specified or derived.

        Three internal encodings are supported: char, wchar, and dchar. The
        methods herein operate upon arrays of this type. For example, read()
        returns an array of the type, whilst write() and append() expect an
        array of said type.

        Supported external encodings are as follow:

                $(UL Encoding.Unknown)
                $(UL Encoding.UTF_8)
                $(UL Encoding.UTF_8N)
                $(UL Encoding.UTF_16)
                $(UL Encoding.UTF_16BE)
                $(UL Encoding.UTF_16LE) 
                $(UL Encoding.UTF_32)
                $(UL Encoding.UTF_32BE)
                $(UL Encoding.UTF_32LE) 

        These can be divided into implicit and explicit encodings. Here are
        the implicit subset:

                $(UL Encoding.Unknown)
                $(UL Encoding.UTF_8)
                $(UL Encoding.UTF_16)
                $(UL Encoding.UTF_32) 

        Implicit encodings may be used to 'discover'
        an unknown encoding, by examining the first few bytes of the file
        content for a signature. This signature is optional for all files, 
        but is often written such that the content is self-describing. When
        the encoding is unknown, using one of the non-explicit encodings will
        cause the read() method to look for a signature and adjust itself 
        accordingly. It is possible that a ZWNBSP character might be confused 
        with the signature; today's files are supposed to use the WORD-JOINER 
        character instead.

        Explicit encodings are as follows:
       
                $(UL Encoding.UTF_8N)
                $(UL Encoding.UTF_16BE)
                $(UL Encoding.UTF_16LE) 
                $(UL Encoding.UTF_32BE)
                $(UL Encoding.UTF_32LE) 
        
        This group of encodings are for use when the file encoding is
        known. These *must* be used when writing or appending, since written
        content must be in a known format. It should be noted that, during a
        read operation, the presence of a signature is in conflict with these 
        explicit varieties.

        Method read() returns the current content of the file, whilst write()
        sets the file content, and file length, to the provided array. Method
        append() adds content to the tail of the file. When appending, it is
        your responsibility to ensure the existing and current encodings are
        correctly matched.

        Methods to inspect the file system, check the status of a file or
        directory, and other facilities are made available via the FilePath
        superclass.

        See these links for more info:
        $(UL $(LINK http://www.utf-8.com/))
        $(UL $(LINK http://www.hackcraft.net/xmlUnicode/))
        $(UL $(LINK http://www.unicode.org/faq/utf_bom.html/))
        $(UL $(LINK http://www.azillionmonkeys.com/qed/unicode.html/))
        $(UL $(LINK http://icu.sourceforge.net/docs/papers/forms_of_unicode/))

*******************************************************************************/

class UnicodeFile(T)
{
        private UnicodeBom!(T)  bom_;
        private char[]          path_;

        /***********************************************************************
        
                Construct a UnicodeFile from the provided FilePath. The given 
                encoding represents the external file encoding, and should
                be one of the Encoding.xx types 

        ***********************************************************************/
                                  
        this (char[] path, Encoding encoding)
        {
                bom_ = new UnicodeBom!(T)(encoding);
                path_ = path;
        }

        /***********************************************************************

                Call-site shortcut to create a UnicodeFile instance. This 
                enables the same syntax as struct usage, so may expose
                a migration path

        ***********************************************************************/

        static UnicodeFile opCall (char[] name, Encoding encoding)
        {
                return new UnicodeFile (name, encoding);
        }

        /***********************************************************************

                Return the associated file path

        ***********************************************************************/

        char[] toString ()
        {
                return path_;
        }
        
        /***********************************************************************

                Return the current encoding. This is either the originally
                specified encoding, or a derived one obtained by inspecting
                the file content for a bom. The latter is performed as part
                of the read() method.

        ***********************************************************************/

        Encoding encoding ()
        {
                return bom_.encoding;
        }
        
        /***********************************************************************

                Return the associated bom instance. Use this to find more
                information about the encoding status

        ***********************************************************************/

        UnicodeBom!(T) bom ()
        {
                return bom_;
        }

        /***********************************************************************

                Return the content of the file. The content is inspected 
                for a bom signature, which is stripped. An exception is
                thrown if a signature is present when, according to the
                encoding type, it should not be. Conversely, An exception
                is thrown if there is no known signature where the current
                encoding expects one to be present.

        ***********************************************************************/

        final T[] read ()
        {
                auto content = File.get (path_);
                return bom_.decode (content);
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.
                The content will be encoded accordingly.

        ***********************************************************************/

        final void write (T[] content, bool writeBom)
        {       
                // convert to external representation (may throw an exeption)
                void[] converted = bom_.encode (content);

                // open file after conversion ~ in case of exceptions
                scope conduit = new File (path_, File.ReadWriteCreate);  
                scope (exit)
                       conduit.close;

                if (writeBom)
                    conduit.write (bom_.signature);

                // and write
                conduit.write (converted);
        }

        /***********************************************************************

                Append content to the file; the content will be encoded 
                accordingly.

                Note that it is your responsibility to ensure the 
                existing and current encodings are correctly matched.

        ***********************************************************************/

        final void append (T[] content)
        {
                // convert to external representation (may throw an exception)
                File.append (path_, bom_.encode (content));
        }
}


/*******************************************************************************

*******************************************************************************/

debug (UnicodeFile)
{
        import tango.io.Stdout;

        void main()
        {       
                auto file = UnicodeFile!(char)("UnicodeFile.d", Encoding.UTF_8);
                auto content = file.read;
                Stdout (content).newline;
        }
}
