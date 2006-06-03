/*******************************************************************************

        @file UnicodeFile.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version; December 2005      

        @author         Kris

*******************************************************************************/

module tango.io.UnicodeFile;

public  import  tango.io.FilePath;
public  import  tango.convert.Unicode;

private import  tango.io.FileProxy,
                tango.io.Exception,
                tango.io.FileConduit;

private import  tango.core.ByteSwap;

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

                Unicode.Unknown 
                Unicode.UTF_8
                Unicode.UTF_8N
                Unicode.UTF_16
                Unicode.UTF_16BE
                Unicode.UTF_16LE 
                Unicode.UTF_32 
                Unicode.UTF_32BE
                Unicode.UTF_32LE 

        These can be divided into non-explicit and explicit encodings:

                Unicode.Unknown 
                Unicode.UTF_8
                Unicode.UTF_16
                Unicode.UTF_32 


                Unicode.UTF_8N
                Unicode.UTF_16BE
                Unicode.UTF_16LE 
                Unicode.UTF_32BE
                Unicode.UTF_32LE 
        
        The former group of non-explicit encodings may be used to 'discover'
        an unknown encoding, by examining the first few bytes of the file
        content for a signature. This signature is optional for all files, 
        but is often written such that the content is self-describing. When
        the encoding is unknown, using one of the non-explicit encodings will
        cause the read() method to look for a signature and adjust itself 
        accordingly. It is possible that a ZWNBSP character might be confused 
        with the signature; today's files are supposed to use the WORD-JOINER 
        character instead.
       
        The group of explicit encodings are for use when the file encoding is
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


        See 
        $(LINK http://www.utf-8.com/)
        $(LINK http://www.hackcraft.net/xmlUnicode/)
        $(LINK http://www.unicode.org/faq/utf_bom.html/)
        $(LINK http://www.azillionmonkeys.com/qed/unicode.html/)
        $(LINK http://icu.sourceforge.net/docs/papers/forms_of_unicode/)

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

                try {
                    // allocate enough space for the entire file
                    auto content = new ubyte [conduit.length];

                    //read the content
                    if (conduit.read (content) != content.length)
                        throw new IOException ("unexpected eof");

                    return unicode.decode (content);
                    } finally {                        
                              conduit.close();
                              }
        }

        /***********************************************************************

                Set the file content and length to reflect the given array.
                The content will be encoded accordingly.

        ***********************************************************************/

        UnicodeFileT write (T[] content, bool bom = false)
        {
                return write (content, FileStyle.ReadWriteCreate, bom);  
        }

        /***********************************************************************

                Append content to the file; the content will be encoded 
                accordingly.

                Note that it is your responsibility to ensure the 
                existing and current encodings are correctly matched.

        ***********************************************************************/

        UnicodeFileT append (T[] content)
        {
                return write (content, FileStyle.WriteAppending, false);  
        }

        /***********************************************************************

                Internal method to perform writing of content. Note that
                the encoding must be of the explicit variety by the time
                we get here.

        ***********************************************************************/

        private final UnicodeFileT write (T[] content, FileStyle.Bits style, bool bom)
        {       
                // convert to external representation
                void[] converted = unicode.encode (content);

                // open file after conversion ~ in case of exceptions
                auto FileConduit conduit = new FileConduit (this, style);  
                
                try {
                    if (bom)
                        conduit.flush (unicode.getSignature);

                    // and write
                    conduit.flush (converted);
                    } finally {
                              conduit.close();
                              }
                return this;
        }
}


// convenience aliases

alias UnicodeFileT!(char)  UnicodeFile;
