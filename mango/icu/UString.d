/*******************************************************************************

        @file UString.d
        
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


        @version        Initial version, October 2004      
        @author         Kris

        Note that this package and documentation is built around the ICU 
        project (http://oss.software.ibm.com/icu/). Below is the license 
        statement as specified by that software:


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        ICU License - ICU 1.8.1 and later

        COPYRIGHT AND PERMISSION NOTICE

        Copyright (c) 1995-2003 International Business Machines Corporation and 
        others.

        All rights reserved.

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, and/or sell copies of the Software, and to permit persons
        to whom the Software is furnished to do so, provided that the above
        copyright notice(s) and this permission notice appear in all copies of
        the Software and that both the above copyright notice(s) and this
        permission notice appear in supporting documentation.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
        OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
        HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL
        INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING
        FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
        NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
        WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

        Except as contained in this notice, the name of a copyright holder
        shall not be used in advertising or otherwise to promote the sale, use
        or other dealings in this Software without prior written authorization
        of the copyright holder.

        ----------------------------------------------------------------------

        All trademarks and registered trademarks mentioned herein are the 
        property of their respective owners.

*******************************************************************************/

module mango.icu.UString;

private import  mango.icu.ICU,
                mango.icu.UChar,
                mango.icu.ULocale;

/*******************************************************************************

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);

/*******************************************************************************

        Bind to the IReadable and IWritable interfaces if we're building 
        along with the mango.io package

*******************************************************************************/

version=Isolated;
version (Isolated)
        {
        private interface ITextOther   {}
        private interface IStringOther {}
        }
     else
        {
        private import  mango.icu.UMango;

        private import  mango.io.model.IReader,
                        mango.io.model.IWriter;

        private interface ITextOther   : IWritable {}
        private interface IStringOther : IReadable {}
        }
          

/*******************************************************************************

        UString is a string class that stores Unicode characters directly 
        and provides similar functionality as the Java String class.

        In ICU, a Unicode string consists of 16-bit Unicode code units. 
        A Unicode character may be stored with either one code unit &#8212; 
        which is the most common case &#8212; or with a matched pair of 
        special code units ("surrogates"). The data type for code units 
        is UChar.

        For single-character handling, a Unicode character code point is 
        a value in the range 0..0x10ffff. ICU uses the UChar32 type for 
        code points.

        Indexes and offsets into and lengths of strings always count code 
        units, not code points. This is the same as with multi-byte char* 
        strings in traditional string handling. Operations on partial 
        strings typically do not test for code point boundaries. If necessary, 
        the user needs to take care of such boundaries by testing for the code 
        unit values or by using functions like getChar32Start() 
        and getChar32Limit()

        UString methods are more lenient with regard to input parameter values 
        than other ICU APIs. In particular:

        - If indexes are out of bounds for a UString object (< 0 or > length) 
          then they are "pinned" to the nearest boundary.

        - If primitive string pointer values (e.g., const wchar* or char*) for 
          input strings are null, then those input string parameters are treated 
          as if they pointed to an empty string. However, this is not the case 
          for char* parameters for charset names or other IDs.
        
*******************************************************************************/

class UString : UText, IStringOther
{
        alias opCat             append;
        alias opIndexAssign     setCharAt;

        /***********************************************************************
        
                Create an empty UString with the specified available space

        ***********************************************************************/

        this (uint space = 0)
        {
                content.length = space;
                mutable = true;
        }

        /***********************************************************************
        
                Create a UString upon the provided content. If said content
                is immutable (read-only) then you might consider setting the
                'mutable' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified.

        ***********************************************************************/

        this (wchar[] content, bool mutable = true)
        {
                setTo (content, mutable);
        }

        /***********************************************************************
        
                Create a UString via the content of a UText. Note that the
                default is to assume the content is immutable (read-only).
                
        ***********************************************************************/
        
        this (UText other, bool mutable = false)
        {
                this (other.get, mutable);
        }

        /***********************************************************************
        
                Create a UString via the content of a UString. If said content
                is immutable (read-only) then you might consider setting the
                'mutable' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via UString 
                methods.

        ***********************************************************************/
        
        this (UString other, bool mutable = true)
        {
                this (other.get, mutable);
        }

        /***********************************************************************
        
                Support for reading content via the IO system

        ***********************************************************************/

        version (Isolated){}
        else
        {
                /***************************************************************
        
                        Internal adapter to handle loading and conversion
                        of UString content. Once constructed, this may be 
                        used as the target for an IReader. Alternatively, 
                        invoke the load() method with an IBuffer of choice.

                ***************************************************************/
        
                class UStringDecoder : StringDecoder16
                {
                        private UString s;

                        // construct a decoder on the given UString
                        this (UConverter c, uint bytes, UString s)
                        {
                                super (c, bytes);
                                this.s = s;
                        }

                        // IReadable adapter to perform the conversion
                        protected void read (IReader r)
                        {
                                load (r.getBuffer);
                        }

                        // read from the provided buffer until we 
                        // either have all the content, or an eof
                        // condition throws an exception.
                        package void load (IBuffer b)
                        {
                                uint produced = super.read (b, s.content);
                                while (toGo)
                                      {
                                      s.expand (toGo);
                                      produced += super.read (b, s.content[produced..$]);
                                      }
                                s.len = produced;
                        }
                }

                /***************************************************************
        
                        Another constructor for loading known content length
                        into a UString.

                ***************************************************************/
        
                this (IBuffer buffer, uint contentLength, UConverter cvt)
                {
                        this (contentLength);
                        UStringDecoder sd = new UStringDecoder (cvt, contentLength, this);
                        sd.load (buffer);
                }

                /***************************************************************
                
                        Read as many bytes from the input as is necessary
                        to produce the expected number of wchar elements.
                        This uses the default wchar handler, which can be
                        altered by binding a StringDecoder to the IReader
                        in use (see UMango for details).

                        We're mutable, so ensure we don't mess with the
                        IO buffers. Interestingly, changing the length 
                        of a D array will account for slice assignments 
                        (it checks the pointer to see if it's a starting
                         point in the pool). Unfortunately, that doesn't
                        catch the case where a slice starts at offset 0,
                        which is where IBuffer slices may come from. 
                        
                        To be safe, we ask the allocator in use whether 
                        the content it provided can be mutated or not.
                        Note that this is not necessary for UText, since 
                        that is a read-only construct.

                ***************************************************************/

                void read (IReader r)
                {
                        r.get (content);
                        len = content.length;
                        mutable = r.getAllocator.isMutable (content);
                }

                /***************************************************************
                
                        Return a streaming decoder that can be used to 
                        populate this UString with a specified number of 
                        input bytes. 

                        This differs from the above read() method in the
                        way content is read: in the above case, exactly
                        the specified number of wchar elements will be
                        converter from the input, whereas in this case 
                        a variable number of wchar elements are converted
                        until 'bytes' have been read from the input. This 
                        is useful in those cases where the original number 
                        of elements has been lost, and only the resultant 
                        converted byte-count remains (a la HTTP).

                        The returned StringDecoder is one-shot only. You may
                        reuse it (both the converter and the byte count) via
                        its reset() method. 

                        One applies the resultant converter directly with an 
                        IReader like so:

                        @code
                        UString s = ...;
                        IReader r = ...;

                        // r >> s.createDecoder(cvt, bytes);
                        r.get (s.createDecoder(cvt, bytes));
                        @endcode

                        which will read the specified number of bytes from
                        the input and convert them to an appropriate number
                        of wchars within the UString. 

                ***************************************************************/

                StringDecoder createDecoder (UConverter c, uint bytes)
                {
                        return new UStringDecoder (c, bytes, this);
                }
        }

        /***********************************************************************
                
                Append text to this UString

        ***********************************************************************/

        UString opCat (UText other)
        {
                return opCat (other.get);
        }

        /***********************************************************************
        
                Append partial text to this UString

        ***********************************************************************/

        UString opCat (UText other, uint start, uint len=uint.max)
        {
                other.pinIndices (start, len);
                return opCat (other.content [start..start+len]);
        }

        /***********************************************************************
        
                Append a single character to this UString

        ***********************************************************************/

        UString opCat (wchar chr)
        {
                return opCat (&chr, 1);
        }

        /***********************************************************************
        
                Append text to this UString

        ***********************************************************************/

        UString opCat (wchar[] chars)
        {
                return opCat (chars, chars.length);
        }

        /***********************************************************************
                
                Converts a sequence of UTF-8 bytes to UChars (UTF-16)

        ***********************************************************************/

        UString opCat (char[] chars)
        {
                uint fmt (wchar* dst, uint len, inout Error e)
                {
                        uint x;

                        u_strFromUTF8 (dst, len, &x, chars, chars.length, e);
                        return x;
                }

                expand (chars.length);
                return format (&fmt, "failed to append UTF char[]");
        }

        /***********************************************************************
                
                Set a section of this UString to the specified character

        ***********************************************************************/

        UString setTo (wchar chr, uint start=0, uint len=uint.max)
        {
                pinIndices (start, len);
                if (! mutable)
                      realloc ();
                content [start..start+len] = chr;
                return this;
        }

        /***********************************************************************
   
                Set the content to the provided array. Parameter 'mutable'
                specifies whether the given array is likely to change. If 
                not, the array is aliased until such time this UString is
                altered.
                     
        ***********************************************************************/

        UString setTo (wchar[] chars, bool mutable = true)
        {
                len = chars.length;
                if ((this.mutable = mutable) == true)
                     content = chars.dup;
                else
                   content = chars;
                return this;
        }

        /***********************************************************************
        
                Replace the content of this UString. If the new content
                is immutable (read-only) then you might consider setting the
                'mutable' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via one of
                these methods.

        ***********************************************************************/

        UString setTo (UText other, bool mutable = true)
        {
                return setTo (other.get, mutable);
        }

        /***********************************************************************
        
                Replace the content of this UString. If the new content
                is immutable (read-only) then you might consider setting the
                'mutable' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via one of
                these methods.

        ***********************************************************************/

        UString setTo (UText other, uint start, uint len, bool mutable = true)
        {
                other.pinIndices (start, len);
                return setTo (other.content [start..start+len], mutable);
        }

        /***********************************************************************
        
                Replace the character at the specified location.

        ***********************************************************************/

        final UString opIndexAssign (wchar chr, uint index)
        in {
                if (index >= len)
                    exception ("index of out bounds"); 
           }
        body
        {
                if (! mutable)
                      realloc ();
                content [index] = chr;
                return this;
        }

        /***********************************************************************
        
                Remove a piece of this UString.

        ***********************************************************************/

        UString remove (uint start, uint length=uint.max)
        {
                pinIndices (start, length);
                if (length)
                    if (start >= len)
                        truncate (start);
                    else
                       {
                       if (! mutable)
                             realloc ();

                       uint i = start + length;
                       memmove (&content[start], &content[i], (len-i) * wchar.sizeof);
                       len -= length;
                       }
                return this;
        }

        /***********************************************************************
        
                Truncate the length of this UString.

        ***********************************************************************/

        UString truncate (uint length=0)
        {
                if (length <= len)
                    len = length;
                return this;
        }

        /***********************************************************************
        
                Insert leading spaces in this UString

        ***********************************************************************/

        UString padLeading (uint count, wchar padChar = 0x0020)
        {
                expand  (count);
                memmove (&content[count], content, len * wchar.sizeof);
                len += count;
                return setTo (padChar, 0, count);
        }

        /***********************************************************************
        
                Append some trailing spaces to this UString.

        ***********************************************************************/

        UString padTrailing (uint length, wchar padChar = 0x0020)
        {
                expand (length);
                len += length;
                return setTo  (padChar, len-length, length);
        }

        /***********************************************************************
        
                Check for available space within the buffer, and expand 
                as necessary.

        ***********************************************************************/

        package final void expand (uint count)
        {
                if ((len + count) > content.length)
                     realloc (count);
        }

        /***********************************************************************
        
                Allocate memory due to a change in the content. We handle 
                the distinction between mutable and immutable here.

        ***********************************************************************/

        private final void realloc (uint count = 0)
        {
                uint size = (content.length + count + 63) & ~63;
                
                if (mutable)
                    content.length = size;
                else
                   {
                   mutable = true;
                   wchar[] x = content;
                   content = new wchar [size];
                   if (len)
                       content[0..len] = x;
                   }
        }

        /***********************************************************************
        
                Internal method to support UString appending

        ***********************************************************************/

        private final UString opCat (wchar* chars, uint count)
        {
                expand (count);
                content[len..len+count] = chars[0..count];
                len += count;
                return this;
        }

        /***********************************************************************
        
                Internal method to support formatting into this UString. 
                This is used by many of the ICU wrappers to append content
                into a UString.

        ***********************************************************************/

        typedef uint delegate (wchar* dst, uint len, inout Error e) Formatter;

        package final UString format (Formatter format, char[] msg)
        {
                Error   e;
                uint    length;

                while (true)
                      {
                      e = e.OK;
                      length = format (&content[len], content.length - len, e);
                      if (e == e.BufferOverflow)
                          expand (length);
                      else
                         break;
                      } 

                if (isError (e))
                    exception (msg);

                len += length;
                return this;
        }
}


/*******************************************************************************

        Immutable (read-only) text -- use UString for mutable strings.

*******************************************************************************/

class UText : ICU, ITextOther
{
        alias opIndex   charAt;

        // the core of the UText and UString attributes. The name 'len'
        // is used rather than the more obvious 'length' since there is
        // a collision with the silly array[length] syntactic sugar ...
        package uint    len;
        package wchar[] content;

        // this should probably be in UString only, but there seems to 
        // be a compiler bug where it doesn't get initialised correctly,
        // and it's perhaps useful to have here for when a UString is
        // passed as a UText argument.
        private bool    mutable;

        // toFolded() argument
        public enum     CaseOption 
                        {
                        Default  = 0, 
                        SpecialI = 1
                        }

        /***********************************************************************
        
                Hidden constructor

        ***********************************************************************/

        private this ()
        {
        }

        /***********************************************************************
        
                Construct read-only wrapper around the given content

        ***********************************************************************/

        this (wchar[] content)
        {
                this.content = content;
                this.len = content.length;
        }

        /***********************************************************************
        
                Support for writing via the Mango IO subsystem

        ***********************************************************************/

        version (Isolated){}
        else
        {
                void write (IWriter w)
                {
                        w.put (get);
                }
        }

        /***********************************************************************
        
                Return the valid content from this UText

        ***********************************************************************/

        final package wchar[] get ()
        {
                return content [0..len];
        }

        /***********************************************************************
        
                Is this UText equal to another?

        ***********************************************************************/

        final override int opEquals (Object o)
        {
                UText other = cast(UText) o;

                if (other)
                    return (other is this || compare (other) == 0);
                return 0;
        }

        /***********************************************************************
        
                Compare this UText to another.

        ***********************************************************************/

        final override int opCmp (Object o)
        {
                UText other = cast(UText) o;

                if (other is this)
                    return 0;
                else
                   if (other)
                       return compare (other);
                return 1;
        }

        /***********************************************************************
        
                Hash this UText

        ***********************************************************************/

        final override uint toHash ()
        {
                return typeid(wchar[]).getHash (&content[0..len]);
        }

        /***********************************************************************
        
                Clone this UText into a UString

        ***********************************************************************/

        final UString copy ()
        {
                return new UString (content);
        }

        /***********************************************************************
        
                Clone a section of this UText into a UString

        ***********************************************************************/

        final UString extract (uint start, uint len=uint.max)
        {
                pinIndices (start, len);
                return new UString (content[start..start+len]);
        }

        /***********************************************************************
        
                Count unicode code points in the length UChar code units of 
                the string. A code point may occupy either one or two UChar 
                code units. Counting code points involves reading all code 
                units.

        ***********************************************************************/

        final uint codePoints (uint start=0, uint length=uint.max)
        {
                pinIndices (start, length);
                return u_countChar32 (&content[start], length);
        }

        /***********************************************************************
        
                Return an indication whether or not there are surrogate pairs
                within the string.

        ***********************************************************************/

        final bool hasSurrogates (uint start=0, uint length=uint.max)
        {
                pinIndices (start, length);
                return codePoints (start, length) != length;
        }

        /***********************************************************************
        
                Return the character at the specified position.

        ***********************************************************************/

        final wchar opIndex (uint index)
        in {
                if (index >= len)
                    exception ("index of out bounds"); 
           }
        body
        {
                return content [index];
        }

        /***********************************************************************
        
                Return the length of the valid content

        ***********************************************************************/

        final uint length ()
        {
                return len;
        }

        /***********************************************************************
        
                The comparison can be done in code unit order or in code 
                point order. They differ only in UTF-16 when comparing 
                supplementary code points (U+10000..U+10ffff) to BMP code 
                points near the end of the BMP (i.e., U+e000..U+ffff). 

                In code unit order, high BMP code points sort after 
                supplementary code points because they are stored as 
                pairs of surrogates which are at U+d800..U+dfff.

        ***********************************************************************/

        final int compare (UText other, bool codePointOrder=false)
        {
                return compare (other.get, codePointOrder); 
        }

        /***********************************************************************
        
                The comparison can be done in code unit order or in code 
                point order. They differ only in UTF-16 when comparing 
                supplementary code points (U+10000..U+10ffff) to BMP code 
                points near the end of the BMP (i.e., U+e000..U+ffff). 

                In code unit order, high BMP code points sort after 
                supplementary code points because they are stored as 
                pairs of surrogates which are at U+d800..U+dfff.

        ***********************************************************************/

        final int compare (wchar[] other, bool codePointOrder=false)
        {
                return u_strCompare (content, len, other, other.length, codePointOrder); 
        }

        /***********************************************************************
        
                The comparison can be done in UTF-16 code unit order or 
                in code point order. They differ only when comparing 
                supplementary code points (U+10000..U+10ffff) to BMP code 
                points near the end of the BMP (i.e., U+e000..U+ffff). 

                In code unit order, high BMP code points sort after 
                supplementary code points because they are stored as
                pairs of surrogates which are at U+d800..U+dfff.

        ***********************************************************************/

        final int compareFolded (UText other, CaseOption option = CaseOption.Default)
        {
                return compareFolded (other.content, option);
        }

        /***********************************************************************
        
                The comparison can be done in UTF-16 code unit order or 
                in code point order. They differ only when comparing 
                supplementary code points (U+10000..U+10ffff) to BMP code 
                points near the end of the BMP (i.e., U+e000..U+ffff). 

                In code unit order, high BMP code points sort after 
                supplementary code points because they are stored as
                pairs of surrogates which are at U+d800..U+dfff.

        ***********************************************************************/

        final int compareFolded (wchar[] other, CaseOption option = CaseOption.Default)
        {
                return compareFolded (get, other, option);
        }

        /***********************************************************************
        
                Does this UText start with specified string?

        ***********************************************************************/

        final bool startsWith (UText other)
        {
                return startsWith (other.get);
        }

        /***********************************************************************
        
                Does this UText start with specified string?

        ***********************************************************************/

        final bool startsWith (wchar[] chars)
        {
                if (len >= chars.length)
                    return compareFolded (content[0..chars.length], chars) == 0;
                return false;
        }

        /***********************************************************************
        
                Does this UText end with specified string?

        ***********************************************************************/

        final bool endsWith (UText other)
        {
                return endsWith (other.get);
        }

        /***********************************************************************
        
                Does this UText end with specified string?

        ***********************************************************************/

        final bool endsWith (wchar[] chars)
        {
                if (len >= chars.length)
                    return compareFolded (content[len-chars.length..len], chars) == 0;
                return false;
        }

        /***********************************************************************
        
                Find the first occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        final uint indexOf (wchar c, uint start=0)
        {
                pinIndex (start);
                wchar* s = u_memchr (&content[start], c, len-start);
                if (s)
                    return s - cast(wchar*) content;
                return uint.max;
        }

        /***********************************************************************
        
                Find the first occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        final uint indexOf (UText other, uint start=0)
        {
                return indexOf (other.get, start);
        }

        /***********************************************************************
        
                Find the first occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        final uint indexOf (wchar[] chars, uint start=0)
        {
                pinIndex (start);
                wchar* s = u_strFindFirst (&content[start], len-start, chars, chars.length);
                if (s)
                    return s - cast(wchar*) content;
                return uint.max;
        }

        /***********************************************************************
        
                Find the last occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        final uint lastIndexOf (wchar c, uint start=uint.max)
        {
                pinIndex (start);
                wchar* s = u_memrchr (content, c, start);
                if (s)
                    return s - cast(wchar*) content;
                return uint.max;
        }

        /***********************************************************************
        
                Find the last occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        final uint lastIndexOf (UText other, uint start=uint.max)
        {
                return lastIndexOf (other.get, start);
        }

        /***********************************************************************
        
                Find the last occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        final uint lastIndexOf (wchar[] chars, uint start=uint.max)
        {
                pinIndex (start);
                wchar* s = u_strFindLast (content, start, chars, chars.length);
                if (s)
                    return s - cast(wchar*) content;
                return uint.max;
        }

        /***********************************************************************

                Lowercase the characters into a seperate UString.

                Casing is locale-dependent and context-sensitive. The 
                result may be longer or shorter than the original. 
        
                Note that the return value refers to the provided destination 
                UString.

        ***********************************************************************/

        final UString toLower (UString dst)
        {
               return toLower (dst, ULocale.Default);
        }

        /***********************************************************************

                Lowercase the characters into a seperate UString.

                Casing is locale-dependent and context-sensitive. The 
                result may be longer or shorter than the original.
        
                Note that the return value refers to the provided destination 
                UString.

        ***********************************************************************/

        final UString toLower (UString dst, inout ULocale locale)
        {
                uint lower (wchar* dst, uint length, inout Error e)
                {
                        return u_strToLower (dst, length, content, len, toString(locale.name), e);
                }

                dst.expand (len + 32);
                return dst.format (&lower, "toLower() failed");
        }

        /***********************************************************************

                Uppercase the characters into a seperate UString.

                Casing is locale-dependent and context-sensitive. The 
                result may be longer or shorter than the original.

                Note that the return value refers to the provided destination 
                UString.

        ***********************************************************************/

        final UString toUpper (UString dst)
        {
               return toUpper (dst, ULocale.Default);
        }

        /***********************************************************************

                Uppercase the characters into a seperate UString.

                Casing is locale-dependent and context-sensitive. The 
                result may be longer or shorter than the original.

                Note that the return value refers to the provided destination 
                UString.

        ***********************************************************************/

        final UString toUpper (UString dst, inout ULocale locale)
        {
                uint upper (wchar* dst, uint length, inout Error e)
                {
                        return u_strToUpper (dst, length, content, len, toString(locale.name), e);
                }

                dst.expand (len + 32);
                return dst.format (&upper, "toUpper() failed");
        }

        /***********************************************************************
        
                Case-fold the characters into a seperate UString.

                Case-folding is locale-independent and not context-sensitive,
                but there is an option for whether to include or exclude 
                mappings for dotted I and dotless i that are marked with 'I' 
                in CaseFolding.txt. The result may be longer or shorter than 
                the original.

                Note that the return value refers to the provided destination 
                UString.

        ***********************************************************************/

        final UString toFolded (UString dst, CaseOption option = CaseOption.Default)
        {
                uint fold (wchar* dst, uint length, inout Error e)
                {
                        return u_strFoldCase (dst, length, content, len, option, e);
                }

                dst.expand (len + 32);
                return dst.format (&fold, "toFolded() failed");
        }

        /***********************************************************************

                Converts a sequence of wchar (UTF-16) to UTF-8 bytes. If
                the output array is not provided, an array of appropriate
                size will be allocated and returned. Where the output is 
                provided, it must be large enough to hold potentially four
                bytes per character for surrogate-pairs or three bytes per
                character for BMP only. Consider using UConverter where
                streaming conversions are required.

                Returns an array slice representing the valid UTF8 content.

        ***********************************************************************/

        final char[] toUtf8 (char[] dst = null)
        {
                uint    x;
                Error   e;

                if (! cast(char*) dst)
                      dst = new char[len * 4];
                      
                u_strToUTF8 (dst, dst.length, &x, content, len, e);
                testError (e, "failed to convert to UTF8");
                return dst [0..x];
        }

        /***********************************************************************
        
                Remove leading and trailing whitespace from this UText.
                Note that we slice the content to remove leading space.

        ***********************************************************************/

        UText trim ()
        {
                wchar   c;
                uint    i = len;

                // cut off trailing white space
                while (i && ((c = charAt(i-1)) == 0x20 || UChar.isWhiteSpace (c)))
                       --i;
                len = i;

                // now remove leading whitespace
                for (i=0; i < len && ((c = charAt(i)) == 0x20 || UChar.isWhiteSpace (c)); ++i) {}
                if (i)
                   {
                   len -= i;
                   content = content[i..$-i];
                   }
                  
                return this;
        }

        /***********************************************************************
        
                Unescape a string of characters and write the resulting
                Unicode characters to the destination buffer.  The following 
                escape sequences are recognized:
                
                  uhhhh       4 hex digits; h in [0-9A-Fa-f]
                  Uhhhhhhhh   8 hex digits
                  xhh         1-2 hex digits
                  x{h...}     1-8 hex digits
                  ooo         1-3 octal digits; o in [0-7]
                  cX          control-X; X is masked with 0x1F
                 
                as well as the standard ANSI C escapes:
                 
                  a => U+0007, \\b => U+0008, \\t => U+0009, \\n => U+000A,
                  v => U+000B, \\f => U+000C, \\r => U+000D, \\e => U+001B,
                  \\" =U+0022, \\' => U+0027, \\? => U+003F, \\\\ => U+005C
                 
                Anything else following a backslash is generically escaped.  
                For example, "[a\\-z]" returns "[a-z]".
                 
                If an escape sequence is ill-formed, this method returns an 
                empty string.  An example of an ill-formed sequence is "\\u" 
                followed by fewer than 4 hex digits.
                 
         ***********************************************************************/

        final UString unEscape () 
        {
                UString result = new UString (len);
                for (uint i=0; i < len;) 
                    {
                    dchar c = charAt(i++);
                    if (c == 0x005C) 
                       {
                       // bump index ...
                       c = u_unescapeAt (&_charAt, &i, len, cast(void*) this); 

                       // error?
                       if (c == 0xFFFFFFFF) 
                          {
                          result.truncate ();   // return empty string
                          break;                // invalid escape sequence
                          }
                       }
                    result.append (c);
                    }
                return result;
        }

        /***********************************************************************
        
                Is this code point a surrogate (U+d800..U+dfff)?

        ***********************************************************************/

        final static bool isSurrogate (wchar c)
        {
                return (c & 0xfffff800) == 0xd800;
        }

        /***********************************************************************
        
                Is this code unit a lead surrogate (U+d800..U+dbff)?

        ***********************************************************************/

        final static bool isLeading (wchar c)
        {
                return (c & 0xfffffc00) == 0xd800;
        }

        /***********************************************************************
        
                Is this code unit a trail surrogate (U+dc00..U+dfff)?

        ***********************************************************************/

        final static bool isTrailing (wchar c)
        {
                return (c & 0xfffffc00) == 0xdc00;
        }

        /***********************************************************************
        
                Adjust a random-access offset to a code point boundary 
                at the start of a code point. If the offset points to 
                the trail surrogate of a surrogate pair, then the offset 
                is decremented. Otherwise, it is not modified.

        ***********************************************************************/

        final uint getCharStart (uint i)
        in {
                if (i >= len)
                    exception ("index of out bounds"); 
           }
        body
        {
                if (isTrailing (content[i]) && i && isLeading (content[i-1]))
                    --i;
                return i;
        }

        /***********************************************************************
        
                Adjust a random-access offset to a code point boundary 
                after a code point. If the offset is behind the lead 
                surrogate of a surrogate pair, then the offset is 
                incremented. Otherwise, it is not modified.

        ***********************************************************************/

        final uint getCharLimit (uint i)
        in {
                if (i >= len)
                    exception ("index of out bounds"); 
           }
        body
        {
                if (i && isLeading(content[i-1]) && isTrailing (content[i]))
                    ++i;
                return i;
        }

        /***********************************************************************
        
                Callback for C unescapeAt() function

        ***********************************************************************/

        extern (C)
        {
                typedef wchar function (uint offset, void* context) CharAt;

                private static wchar _charAt (uint offset, void* context)
                {
                        return (cast(UString) context).charAt (offset);
                }
        }

        /***********************************************************************
        
                Pin the given index to a valid position.

        ***********************************************************************/

        final private void pinIndex (inout uint x)
        {
                if (x > len)
                    x = len;
        }

        /***********************************************************************
        
                Pin the given index and length to a valid position.

        ***********************************************************************/

        final private void pinIndices (inout uint start, inout uint length)
        {
                if (start > len) 
                    start = len;

                if (length > (len - start))
                    length = len - start;
        }

        /***********************************************************************
        
                Helper for comparison methods

        ***********************************************************************/

        final private int compareFolded (wchar[] s1, wchar[] s2, CaseOption option = CaseOption.Default)
        {
                Error e;

                int x = u_strCaseCompare (s1, s1.length, s2, s2.length, option, e);
                testError (e, "compareFolded failed");
                return x; 
        }


        /***********************************************************************
        
                Bind the ICU functions from a shared library. This is
                complicated by the issues regarding D and DLLs on the
                Windows platform

        ***********************************************************************/
                
        private static void* library;

        /***********************************************************************

        ***********************************************************************/

        private static extern (C) 
        {
                wchar* function (wchar*, uint, wchar*, uint) u_strFindFirst;
                wchar* function (wchar*, uint, wchar*, uint) u_strFindLast;
                wchar* function (wchar*, wchar, uint) u_memchr;
                wchar* function (wchar*, wchar, uint) u_memrchr;
                int    function (wchar*, uint, wchar*, uint, bool) u_strCompare;
                int    function (wchar*, uint, wchar*, uint, uint, inout Error) u_strCaseCompare;
                dchar  function (CharAt, uint*, uint, void*) u_unescapeAt;
                uint   function (wchar*, uint) u_countChar32;
                uint   function (wchar*, uint, wchar*, uint, char*, inout Error) u_strToUpper;
                uint   function (wchar*, uint, wchar*, uint, char*, inout Error) u_strToLower;
                uint   function (wchar*, uint, wchar*, uint, uint, inout Error) u_strFoldCase;
                wchar* function (wchar*, uint, uint*, char*, uint, inout Error) u_strFromUTF8;
                char*  function (char*, uint, uint*, wchar*, uint, inout Error) u_strToUTF8;
        }

        /***********************************************************************

        ***********************************************************************/

        static  FunctionLoader.Bind[] targets = 
                [
                {cast(void**) &u_strFindFirst,      "u_strFindFirst"},
                {cast(void**) &u_strFindLast,       "u_strFindLast"},
                {cast(void**) &u_memchr,            "u_memchr"},
                {cast(void**) &u_memrchr,           "u_memrchr"},
                {cast(void**) &u_strCompare,        "u_strCompare"},
                {cast(void**) &u_strCaseCompare,    "u_strCaseCompare"},
                {cast(void**) &u_unescapeAt,        "u_unescapeAt"},
                {cast(void**) &u_countChar32,       "u_countChar32"},
                {cast(void**) &u_strToUpper,        "u_strToUpper"},
                {cast(void**) &u_strToLower,        "u_strToLower"},
                {cast(void**) &u_strFoldCase,       "u_strFoldCase"},
                {cast(void**) &u_strFromUTF8,       "u_strFromUTF8"},
                {cast(void**) &u_strToUTF8,         "u_strToUTF8"},
                ];

        /***********************************************************************

        ***********************************************************************/

        static this ()
        {
                library = FunctionLoader.bind (icuuc, targets);
                //test ();
        }

        /***********************************************************************

        ***********************************************************************/

        static ~this ()
        {
                FunctionLoader.unbind (library);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void test()
        {
                UString s = new UString (r"aaaqw \uabcd eaaa");
                char[] x = "dssfsdff";
                s ~ x ~ x;
                wchar c = s[3];
                s[3] = 'Q';
                int y = s.indexOf ("qwe");
                s.unEscape ();
                s.toUpper (new UString);
                s.padLeading(2).padTrailing(2).trim();
        }
}
