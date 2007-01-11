/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005
              
        author:         Kris


        ---
        class String(T) : StringView!(T)
        {
                // set or reset the content 
                String set (T[] chars, bool mutable=true);
                String set (String other, bool mutable=true);

                // get the index and length of the current selection
                uint selection (inout int length);

                // make a selection
                String select (int start=0, int length=int.max);

                // move the selection around
                bool select (T c);
                bool select (T[] chars);
                bool select (String other);
                bool selectPrior (T c);
                bool selectPrior (T[] chars);
                bool selectPrior (String other);

                // append behind current selection
                String append (String other);
                String append (T[] other);
                String append (T chr, int count=1);
                String append (int value, options);
                String append (long value, options);
                String append (double value, options);

                // transcode behind current selection
                String encode (char[]);
                String encode (wchar[]);
                String encode (dchar[]);
                
                // insert before current selection
                String prepend (T[] other);
                String prepend (String other);
                String prepend (T chr, int count=1);

                // replace current selection
                String replace (T chr);
                String replace (T[] other);
                String replace (String other);

                // remove current selection
                String remove ();

                // clear content
                String clear ();

                // trim content
                String trim ();

                // truncate at point, or current selection
                String truncate (int point = int.max);

                // return content
                T[] slice ();
        }

        class StringView(T) : UniString
        {
                // iterate across content
                opApply (int delegate(inout T) dg);

                // hash content
                uint toHash ();

                // return length of content
                uint length ();

                // compare content
                bool equals  (T[] other);
                bool equals  (StringView other);
                bool ends    (T[] other);
                bool ends    (StringView other);
                bool starts  (T[] other);
                bool starts  (StringView other);
                int compare  (T[] other);
                int compare  (StringView other);
                int opEquals (Object other);
                int opCmp    (Object other);

                // copy content
                T[] copy (T[] dst);
                T[] copy ();
                
                String!(T) clone ();

                // replace the comparison algorithm 
                Comparator setComparator (Comparator comparator);
        }

        class UniString
        {
                // convert content
                abstract char[]  toUtf8  (char[]  dst = null);
                abstract wchar[] toUtf16 (wchar[] dst = null);
                abstract dchar[] toUtf32 (dchar[] dst = null);
        }
        ---

*******************************************************************************/

module tango.text.String;

private import  Util = tango.text.Util;

private import  Utf = tango.text.convert.Utf;

private import  Float = tango.text.convert.Float;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);


/*******************************************************************************

        String is a class for storing and manipulating Unicode characters.

        String maintains a current "selection", controlled via the 
        select() and rselect() methods. Append(), prepend(), replace() and
        remove() each operate with respect to the selection. The select()
        methods themselves operate with respect to the current selection
        also, providing a means of iterating across matched patterns. To
        reset the selection to the entire string, use the select() method 
        with no arguments. 
       
        Indexes and lengths of content always count code units, not code 
        points. This is similar to traditional ascii string handling, yet
        indexing is rarely used in practice due to the selection idiom:
        substring indexing is generally implied as opposed to manipulated
        directly. This allows for a more streamlined model with regard to
        surrogates.

*******************************************************************************/

class String(T) : StringView!(T)
{
        public  alias get               opIndex;
        private alias StringView!(T)    StringViewT;

        private bool                    mutable;
        private Comparator              comparator;
        private uint                    selectPoint,
                                        selectLength;

        /***********************************************************************
        
                Default ctor

        ***********************************************************************/

        this ()
        {
                this.comparator = &simpleComparator;
        }

        /***********************************************************************
        
                Create an empty String with the specified available 
                space

        ***********************************************************************/

        this (uint space)
        {
                this();
                mutable = true;
                content.length = space;
        }

        /***********************************************************************
        
                Create a String upon the provided content. If said 
                content is immutable (read-only) then you might consider 
                setting the 'copy' parameter to false. Doing so will 
                avoid allocating heap-space for the content until it is 
                modified via String methods.

        ***********************************************************************/

        this (T[] content, bool copy = true)
        {
                this();
                set (content, copy);
        }

        /***********************************************************************
        
                Create a String via the content of another.
                
                If said content is immutable (read-only) then you might 
                consider setting the 'copy' parameter to false. Doing 
                so will avoid allocating heap-space for the content until 
                it is modified via String methods.

        ***********************************************************************/
        
        this (StringViewT other, bool copy = true)
        {
                this();
                set (other.get, copy);
        }

        /***********************************************************************
   
                Set the content to the provided array. Parameter 'copy'
                specifies whether the given array is likely to change. If 
                not, the array is aliased until such time it is altered via
                this class.
                     
        ***********************************************************************/

        final String set (T[] chars, bool copy = true)
        {
                contentLength = chars.length;
                select (0, contentLength);

                if ((this.mutable = copy) is true)
                     content = chars.dup;
                else
                   content = chars;
                return this;
        }

        /***********************************************************************
        
                Replace the content of this String. If the new content
                is immutable (read-only) then you might consider setting the
                'copy' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via one of
                these methods.

        ***********************************************************************/

        final String set (StringViewT other, bool copy = true)
        {
                return set (other.get, copy);
        }

        /***********************************************************************

                Return the index and length of the current selection

        ***********************************************************************/

        final uint selection (inout int length)
        {
                length = selectLength;
                return selectPoint;
        }

        /***********************************************************************

                Explicitly set the current selection

        ***********************************************************************/

        final String select (int start=0, int length=int.max)
        {
                pinIndices (start, length);
                selectPoint = start;
                selectLength = length;                
                return this;
        }

        /***********************************************************************
        
                Find and select the next occurrence of a BMP code point
                in a string. A surrogate code point is found only if its
                match in the text is not part of a surrogate pair.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool select (T c)
        {
                auto s = get();
                auto x = Util.locate (s, c, selectPoint);
                if (x < s.length)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find and select the next substring occurrence. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool select (StringViewT other)
        {
                return select (other.get);
        }

        /***********************************************************************
        
                Find and select the next substring occurrence. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool select (T[] chars)
        {
                auto s = get();
                auto x = Util.locatePattern (s, chars, selectPoint);
                if (x < s.length)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find and select a prior occurrence of a BMP code point
                in a string. A surrogate code point is found only if
                its match in the text is not part of a surrogate pair.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (T c)
        {
                auto s = get();
                auto x = Util.locatePrior (s, c, selectPoint);               
                if (x < s.length)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find and select a prior substring occurrence. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (StringViewT other)
        {
                return selectPrior (other.get);
        }

        /***********************************************************************
        
                Find and select a prior substring occurrence. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

                Return true if found, false otherwise

        ***********************************************************************/

        final bool selectPrior (T[] chars)
        {
                auto s = get();
                auto x = Util.locatePatternPrior (s, chars, selectPoint);
                if (x < s.length)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Append partial text to this String

        ***********************************************************************/

        final String append (StringViewT other)
        {
                return append (other.get);
        }

        /***********************************************************************
        
                Append text to this String

        ***********************************************************************/

        final String append (T[] chars)
        {
                return append (chars.ptr, chars.length);
        }

        /***********************************************************************
        
                Append a count of characters to this String

        ***********************************************************************/

        final String append (T chr, int count=1)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                return set (chr, point, count);
        }

        /***********************************************************************
        
                Append an integer to this String

        ***********************************************************************/

        final String append (int v, Integer.Format fmt=Integer.Format.Signed)
        {
                return append (cast(long) v, fmt);
        }

        /***********************************************************************
        
                Append a long to this String

        ***********************************************************************/

        final String append (long v, Integer.Format fmt=Integer.Format.Signed)
        {
                T[64] tmp = void;
                return append (Integer.format(tmp, v, fmt));
        }

        /***********************************************************************
        
                Append a double to this String

        ***********************************************************************/

        final String append (double v, uint decimals=6, bool scientific=false)
        {
                T[64] tmp = void;
                return append (Float.format(tmp, v, decimals, scientific));
        }

        /***********************************************************************
        
                Insert characters into this String

        ***********************************************************************/

        final String prepend (T chr, int count=1)
        {
                expand (selectPoint, count);
                return set (chr, selectPoint, count);
        }

        /***********************************************************************
        
                Insert text into this String

        ***********************************************************************/

        final String prepend (T[] other)
        {
                expand (selectPoint, other.length);
                content[selectPoint..selectPoint+other.length] = other;
                return this;
        }

        /***********************************************************************
        
                Insert another String into this String

        ***********************************************************************/

        final String prepend (StringViewT other)
        {       
                return prepend (other.get);
        }

        /***********************************************************************

                Append encoded text at the current selection point. The text
                is converted as necessary to the appropritate utf encoding.

                Returns a chaining reference
                
        ***********************************************************************/

        final String encode (char[] s)
        {
                T[1024] tmp = void;
                
                static if (is (T == char))
                           return append(s);
                
                static if (is (T == wchar))
                           return append (Utf.toUtf16(s, tmp));
                
                static if (is (T == dchar))
                           return append (Utf.toUtf32(s, tmp));
        }

        /// ditto
        final String encode (wchar[] s)
        {
                T[1024] tmp = void;
                                
                static if (is (T == char))
                           return append (Utf.toUtf8(s, tmp));
                
                static if (is (T == wchar))
                           return append (s);
                
                static if (is (T == dchar))
                           return append (Utf.toUtf32(s, tmp));
        }
        
        /// ditto
        final String encode (dchar[] s)
        {
                T[1024] tmp = void;
                                
                static if (is (T == char))
                           return append (Utf.toUtf8(s, tmp));
                
                static if (is (T == wchar))
                           return append (Utf.toUtf16(s, tmp));
                
                static if (is (T == dchar))
                           return append (s);
        }

        /// ditto
        final String encode (Object o)
        {
                return encode (o.toUtf8);
        }
        
        /***********************************************************************
                
                Replace a section of this String with the specified 
                character

        ***********************************************************************/

        final String replace (T chr)
        {
                return set (chr, selectPoint, selectLength);
        }

        /***********************************************************************
                
                Replace a section of this String with the specified 
                array

        ***********************************************************************/

        final String replace (T[] chars)
        {
                int chunk = chars.length - selectLength;
                if (chunk >= 0)
                    expand (selectPoint, chunk);
                else
                   remove (-chunk);

                content [selectPoint .. selectPoint+chars.length] = chars;
                select (selectPoint, chars.length);
                return this;
        }

        /***********************************************************************
                
                Replace a section of this String with the specified 
                String

        ***********************************************************************/

        final String replace (StringViewT other)
        {
                return replace (other.get);
        }

        /***********************************************************************
        
                Remove the selection from this String and reset the
                selection to zero length

        ***********************************************************************/

        final String remove ()
        {
                remove (selectLength);
                return select (selectPoint, 0);
        }

        /***********************************************************************
        
                Remove the selection from this String and reset the
                selection to zero length

        ***********************************************************************/

        private int remove (int count)
        {
                int start = selectPoint;
                pinIndices (start, count);
                if (count > 0)
                   {
                   if (! mutable)
                         realloc ();

                   uint i = start + count;
                   memmove (content.ptr+start, content.ptr+i, (contentLength-i) * T.sizeof);
                   contentLength -= count;
                   }
                return count;
        }

        /***********************************************************************
        
                Truncate this string. Default behaviour is to truncate at 
                the current append point. Current selection is moved to the
                truncation point, with length 0

        ***********************************************************************/

        final String truncate (int index = int.max)
        {
                if (index is int.max)
                    index = selectPoint + selectLength;

                pinIndex (index);
                return select (contentLength = index, 0);
        }

        /***********************************************************************
        
                Clear the string content

        ***********************************************************************/

        final String clear ()
        {
                return select (contentLength = 0, 0);
        }

        /***********************************************************************
        
                Remove leading and trailing whitespace from this String,
                and reset the selection to the trimmed content

        ***********************************************************************/

        final String trim ()
        {
                content = Util.trim (get());
                select (0, contentLength = content.length);
                return this;
        }

        /***********************************************************************
        
                Return an alias to the content of this String

        ***********************************************************************/

        final T[] slice ()
        {
                return get ();
        }



        /* ====================== StringView methods ======================== */



        /***********************************************************************
        
                Get the encoding type

        ***********************************************************************/        

        final TypeInfo encoding()
        {
                return typeid(T);
        }

        /***********************************************************************
        
                Set the comparator delegate

        ***********************************************************************/

        final Comparator setComparator (Comparator comparator)
        {
                assert (comparator);
                
                auto tmp = this.comparator;
                this.comparator = comparator;
                return tmp;
        }

        /***********************************************************************
        
                Hash this String

        ***********************************************************************/

        override uint toHash ()
        {
                return Util.jhash (cast(ubyte*) content.ptr, contentLength * T.sizeof);
        }

        /***********************************************************************
        
                Return the length of the valid content

        ***********************************************************************/

        final uint length ()
        {
                return contentLength;
        }

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        final bool equals (StringViewT other)
        {
                if (other is this)
                    return true;
                return equals (other.get);
        }

        /***********************************************************************
        
                Is this String equal to the the provided text?

        ***********************************************************************/

        final bool equals (T[] other)
        {
                if (other.length == contentLength)
                    return Util.matching (other.ptr, content.ptr, contentLength);
                return false;
        }

        /***********************************************************************
        
                Does this String end with another?

        ***********************************************************************/

        final bool ends (StringViewT other)
        {
                return ends (other.get);
        }

        /***********************************************************************
        
                Does this String end with the specified string?

        ***********************************************************************/

        final bool ends (T[] chars)
        {
                if (chars.length <= contentLength)
                    return Util.matching (content.ptr+(contentLength-chars.length), chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************
        
                Does this String start with another?

        ***********************************************************************/

        final bool starts (StringViewT other)
        {
                return starts (other.get);
        }

        /***********************************************************************
        
                Does this String start with the specified string?

        ***********************************************************************/

        final bool starts (T[] chars)
        {
                if (chars.length <= contentLength)                
                    return Util.matching (content.ptr, chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************
        
                Compare this String start with another. Returns 0 if the 
                content matches, less than zero if this String is "less"
                than the other, or greater than zero where this String 
                is "bigger".

        ***********************************************************************/

        final int compare (StringViewT other)
        {
                if (other is this)
                    return 0;

                return compare (other.get);
        }

        /***********************************************************************
        
                Compare this String start with an array. Returns 0 if the 
                content matches, less than zero if this String is "less"
                than the other, or greater than zero where this String 
                is "bigger".

        ***********************************************************************/

        final int compare (T[] chars)
        {
                return comparator (get(), chars);
        }

        /***********************************************************************
        
                Return content from this String 
                
                A slice of dst is returned, representing a copy of the 
                content. The slice is clipped to the minimum of either 
                the length of the provided array, or the length of the 
                content minus the stipulated start point

        ***********************************************************************/

        final T[] copy (T[] dst)
        {
                uint i = contentLength;
                if (i > dst.length)
                    i = dst.length;

                return dst [0 .. i] = content [0 .. i];
        }

        /***********************************************************************
        
                Return dup'd content from this String 

        ***********************************************************************/

        final T[] copy ()
        {
                return content [0 .. contentLength].dup;
        }

        /***********************************************************************

                Clone this string, with a copy of the content also
                
        ***********************************************************************/

        final String clone ()
        {
                return new String!(T)(get);
        }

        /***********************************************************************

                Convert to the UniString types. The optional argument
                dst will be resized as required to house the conversion. 
                To minimize heap allocation during subsequent conversions,
                apply the following pattern:

                        String  string;

                        wchar[] buffer;
                        wchar[] result = string.utf16 (buffer);

                        if (result.length > buffer.length)
                            buffer = result;

               You can also provide a buffer from the stack, but the output 
               will be moved to the heap if said buffer is not large enough

        ***********************************************************************/

        final char[] toUtf8 (char[] dst = null)
        {
                static if (is (T == char))
                           return get();
                
                static if (is (T == wchar))
                           return Utf.toUtf8 (get(), dst);
                
                static if (is (T == dchar))
                           return Utf.toUtf8 (get(), dst);
        }
        
        /// ditto
        final wchar[] toUtf16 (wchar[] dst = null)
        {
                static if (is (T == char))
                           return Utf.toUtf16 (get(), dst);
                
                static if (is (T == wchar))
                           return get();
                
                static if (is (T == dchar))
                           return Utf.toUtf16 (get(), dst);
        }
        
        /// ditto
        final dchar[] toUtf32 (dchar[] dst = null)
        {
                static if (is (T == char))
                           return Utf.toUtf32 (get(), dst);
                
                static if (is (T == wchar))
                           return Utf.toUtf32 (get(), dst);
                
                static if (is (T == dchar))
                           return get();
        }

        /**********************************************************************

                Iterate over the characters in this string. Note that 
                this is a read-only freachable: the worst a user can
                do is alter the temporary 'c'

        **********************************************************************/

        final int opApply (int delegate(inout T) dg)
        {
                int result = 0;

                foreach (T c; get())
                         if ((result = dg (c)) != 0)
                             break;
                return result;
        }

        /***********************************************************************
        
                Compare this String to another. We compare against other
                Strings only. Literals and other objects are not supported

        ***********************************************************************/

        override int opCmp (Object o)
        {
                auto other = cast (StringViewT) o;

                if (other is null)
                    return -1;

                return compare (other);
        }

        /***********************************************************************
        
                Is this String equal to the text of something else?

        ***********************************************************************/

        override int opEquals (Object o)
        {
                auto other = cast (StringViewT) o;

                if (other)
                    return equals (other);

                // this can become expensive ...
                char[1024] tmp = void;
                return this.toUtf8(tmp) == o.toUtf8;
        }

        /// ditto
        final int opEquals (T[] s)
        {
                return get() == s;
        }
        
        /***********************************************************************
        
                Throw an exception

        ***********************************************************************/

        final void error (char[] msg)
        {
                throw new TextException (msg);
        }

        /***********************************************************************
        
                Pin the given index to a valid position.

        ***********************************************************************/

        private void pinIndex (inout int x)
        {
                if (x > contentLength)
                    x = contentLength;
        }

        /***********************************************************************
        
                Pin the given index and length to a valid position.

        ***********************************************************************/

        private void pinIndices (inout int start, inout int length)
        {
                if (start > contentLength) 
                    start = contentLength;

                if (length > (contentLength - start))
                    length = contentLength - start;
        }

        /***********************************************************************
        
                Simple comparator

                Compare two arrays. Returns 0 if the content matches, less 
                than zero if A is "less" than B, or greater than zero where 
                A is "bigger". Where the substrings match, the shorter is 
                considered "less".

        ***********************************************************************/

        private int simpleComparator (T[] a, T[] b)
        {
                uint i = a.length;
                if (b.length < i)
                    i = b.length;

                for (int j, k; j < i; ++j)
                     if ((k = a[j] - b[j]) != 0)
                          return k;
                
                return a.length - b.length;
        }

        /***********************************************************************
        
                make room available to insert or append something

        ***********************************************************************/

        private void expand (uint index, uint count)
        {
                if (!mutable || (contentLength + count) > content.length)
                     realloc (count);

                memmove (content.ptr+index+count, content.ptr+index, (contentLength - index) * T.sizeof);
                selectLength += count;
                contentLength += count;                
        }
                
        /***********************************************************************
                
                Replace a section of this String with the specified 
                character

        ***********************************************************************/

        private String set (T chr, uint start, uint count)
        {
                content [start..start+count] = chr;
                return this;
        }

        /***********************************************************************
        
                Allocate memory due to a change in the content. We handle 
                the distinction between mutable and immutable here.

        ***********************************************************************/

        private void realloc (uint count = 0)
        {
                uint size = (content.length + count + 127) & ~127;
                
                if (mutable)
                    content.length = size;
                else
                   {
                   mutable = true;
                   T[] x = content;
                   content = new T[size];
                   if (contentLength)
                       content[0..contentLength] = x;
                   }
        }

        /***********************************************************************
        
                Internal method to support String appending

        ***********************************************************************/

        private String append (T* chars, uint count)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                content[point .. point+count] = chars[0 .. count];
                return this;
        }
}       



/*******************************************************************************

        Immutable string

*******************************************************************************/

class StringView(T) : UniString
{
        private T[]     content;
        private uint    contentLength;

        public typedef int delegate (T[] a, T[] b) Comparator;

        /***********************************************************************
        
                Set the comparator delegate

        ***********************************************************************/

        abstract Comparator setComparator (Comparator comparator);

        /***********************************************************************
        
        ***********************************************************************/

        abstract String!(T) clone ();

        /***********************************************************************
        
                Hash this String

        ***********************************************************************/

        abstract uint toHash ();

        /***********************************************************************
        
                Return the length of the valid content

        ***********************************************************************/

        abstract uint length ();

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        abstract bool equals (StringView other);

        /***********************************************************************
        
                Is this String equal to the the provided text?

        ***********************************************************************/

        abstract bool equals (T[] other);

        /***********************************************************************
        
                Does this String end with another?

        ***********************************************************************/

        abstract bool ends (StringView other);

        /***********************************************************************
        
                Does this String end with the specified string?

        ***********************************************************************/

        abstract bool ends (T[] chars);

        /***********************************************************************
        
                Does this String start with another?

        ***********************************************************************/

        abstract bool starts (StringView other);

        /***********************************************************************
        
                Does this String start with the specified string?

        ***********************************************************************/

        abstract bool starts (T[] chars);

        /***********************************************************************
        
                Compare this String start with another. Returns 0 if the 
                content matches, less than zero if this String is "less"
                than the other, or greater than zero where this String 
                is "bigger".

        ***********************************************************************/

        abstract int compare (StringView other);

        /***********************************************************************
        
                Compare this String start with an array. Returns 0 if the 
                content matches, less than zero if this String is "less"
                than the other, or greater than zero where this String 
                is "bigger".

        ***********************************************************************/

        abstract int compare (T[] chars);

        /***********************************************************************
        
                Return content from this String 
                
                A slice of dst is returned, representing a copy of the 
                content. The slice is clipped to the minimum of either 
                the length of the provided array, or the length of the 
                content minus the stipulated start point

        ***********************************************************************/

        abstract T[] copy (T[] dst);

        /***********************************************************************
        
                Return dup'd content from this String 

        ***********************************************************************/

        abstract T[] copy ();

        /**********************************************************************

                Iterate over the characters in this string. Note that 
                this is a read-only freachable ~ the worst a user can
                do is alter the temporary 'c'

        ***********************************************************************/

        abstract int opApply (int delegate(inout T) dg);

        /***********************************************************************
        
                Compare this StringView to another

        ***********************************************************************/

        abstract int opCmp (Object o);

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        abstract int opEquals (Object other);

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        abstract int opEquals (T[] other);

        /***********************************************************************
        
                Return the valid content from this String

        ***********************************************************************/

        private final T[] get ()
        {
                return content [0 .. contentLength];
        }
}       


/*******************************************************************************

        A string abstraction that converts to anything

*******************************************************************************/

class UniString
{
        abstract char[]  toUtf8  (char[]  dst = null);

        abstract wchar[] toUtf16 (wchar[] dst = null);

        abstract dchar[] toUtf32 (dchar[] dst = null);

        abstract TypeInfo encoding();
}


/*******************************************************************************

        Exception thrown by String et al

*******************************************************************************/

class TextException : Exception
{
        this (char[] msg)
        {
                super (msg);
        }
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        unittest
        {
        auto s = new String!(dchar)("hello");
        
        s.select ("hello");
        s.replace ("1");
        assert (s == "1");

        assert (s.clear == "");

        assert (s.append(12345) == "12345");
        
        assert (s.clear.append(1.2345, 4) == "1.2345");
        
        assert (s.clear.append(0xf0, Integer.Format.Binary) == "11110000");
        
        assert (s.clear.encode("one"d).toUtf8 == "one");

        assert (Util.delineate(s.clear.append("a\nb").slice).length is 2);
        }
}
