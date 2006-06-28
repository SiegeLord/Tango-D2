/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005      
        
        author:         Kris

*******************************************************************************/

module tango.io.UnicodeFile;

public  import  tango.io.FilePath;

public  import  tango.convert.Unicode;

private import  tango.io.FileProxy,
                tango.io.Exception,
                tango.io.FileConduit;

private import  tango.convert.UnicodeBom;

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

        Supported external encodings are as follow (from Unicode.d):

                $(UL Unicode.Unknown)
                $(UL Unicode.UTF_8)
                $(UL Unicode.UTF_8N)
                $(UL Unicode.UTF_16)
                $(UL Unicode.UTF_16BE)
                $(UL Unicode.UTF_16LE) 
                $(UL Unicode.UTF_32)
                $(UL Unicode.UTF_32BE)
                $(UL Unicode.UTF_32LE) 

        These can be divided into implicit and explicit encodings:

                $(UL Unicode.Unknown)
                $(UL Unicode.UTF_8)
                $(UL Unicode.UTF_16)
                $(UL Unicode.UTF_32) 

        The above group of implicit encodings may be used to 'discover'
        an unknown encoding, by examining the first few bytes of the file
        content for a signature. This signature is optional for all files, 
        but is often written such that the content is self-describing. When
        the encoding is unknown, using one of the non-explicit encodings will
        cause the read() method to look for a signature and adjust itself 
        accordingly. It is possible that a ZWNBSP character might be confused 
        with the signature; today's files are supposed to use the WORD-JOINER 
        character instead.
       
                $(UL Unicode.UTF_8N)
                $(UL Unicode.UTF_16BE)
                $(UL Unicode.UTF_16LE) 
                $(UL Unicode.UTF_32BE)
                $(UL Unicode.UTF_32LE) 
        
        This group of explicit encodings are for use when the file encoding is
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
        directory, and other facilities are made available via the FileProxy
        superclass.

        See these links for more info:
        $(UL $(LINK http://www.utf-8.com/))
        $(UL $(LINK http://www.hackcraft.net/xmlUnicode/))
        $(UL $(LINK http://www.unicode.org/faq/utf_bom.html/))
        $(UL $(LINK http://www.azillionmonkeys.com/qed/unicode.html/))
        $(UL $(LINK http://icu.sourceforge.net/docs/papers/forms_of_unicode/))

*******************************************************************************/

class UnicodeFileT(T) : FileProxy
{
        private UnicodeBomT!(T) unicode;

        /***********************************************************************
        
                Construct a UnicodeFile from the provided FilePath. The given 
                encoding represents the external file encoding, and should
                be one of the Unicode.xx types 

        ***********************************************************************/
                                  
        this (FilePath path, int encoding)
        {
                super (path);
                unicode = new UnicodeBomT!(T)(encoding);
        }

        /***********************************************************************
        
                Construct a UnicodeFile from a text string. The provided 
                encoding represents the external file encoding, and should
                be one of the Unicode.xx types 

        ***********************************************************************/

        this (char[] path, int encoding)
        {
                this (new FilePath(path), encoding);
        }

        /***********************************************************************

                Return the current encoding. This is either the originally
                specified encoding, or a derived one obtained by inspecting
                the file content for a BOM. The latter is performed as part
                of the read() method.

        ***********************************************************************/

        int getEncoding ()
        {
                return unicode.getEncoding();
        }
        
        /***********************************************************************

                Return the content of the file. The content is inspected 
                for a BOM signature, which is stripped. An exception is
                thrown if a signature is present when, according to the
                encoding type, it should not be. Conversely, An exception
                is thrown if there is no known signature where the current
                encoding expects one to be present.

        ***********************************************************************/

        T[] read ()
        {
                auto conduit = new FileConduit (this);  
                scope (exit)
                       conduit.close();

                // allocate enough space for the entire file
                auto content = new ubyte [cast(uint) conduit.length];

                //read the content
                if (conduit.read (content) != content.length)
                    throw new IOException ("unexpected eof");

                return unicode.decode (content);
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.
                The content will be encoded accordingly.

        ***********************************************************************/

        UnicodeFileT write (T[] content, bool bom = false)
        {
                return write (content, FileConduit.ReadWriteCreate, bom);  
        }

        /***********************************************************************

                Append content to the file; the content will be encoded 
                accordingly.

                Note that it is your responsibility to ensure the 
                existing and current encodings are correctly matched.

        ***********************************************************************/

        UnicodeFileT append (T[] content)
        {
                return write (content, FileConduit.WriteAppending, false);  
        }

        /***********************************************************************

                Internal method to perform writing of content. Note that
                the encoding must be of the explicit variety by the time
                we get here.

        ***********************************************************************/

        private final UnicodeFileT write (T[] content, FileConduit.Style style, bool bom)
        {       
                // convert to external representation (may throw an exeption)
                void[] converted = unicode.encode (content);

                // open file after conversion ~ in case of exceptions
                auto conduit = new FileConduit (this, style);  
                scope (exit)
                       conduit.close();

                if (bom)
                    conduit.flush (unicode.getSignature);

                // and write
                conduit.flush (converted);
                return this;
        }
}


// convenience aliases

alias UnicodeFileT!(char)  UnicodeFile;
