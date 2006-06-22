/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005
              
        author:         Kris


        ---
        class MutableString(T) : String!(T)
        {
                // set or reset the content 
                MutableString set (T[] chars, bool mutable=true);
                MutableString set (String other, bool mutable=true);

                // get the index and length of the current selection
                uint selection (inout int length);

                // make a selection
                MutableString select (int start=0, int length=int.max);

                // move the selection around
                bool select (T c);
                bool select (T[] chars);
                bool select (String other);
                bool rselect (T c);
                bool rselect (T[] chars);
                bool rselect (String other);

                // append behind current selection
                MutableString append (String other);
                MutableString append (char[] other);
                MutableString append (wchar[] other);
                MutableString append (dchar[] other);
                MutableString append (T chr, int count=1);
                MutableString append (int value, T[] format=null);
                MutableString append (long value, T[] format=null);
                MutableString append (double value, T[] format=null);

                // format and layout behind current selection
                MutableString format (T[] format, ...);
                MutableString layout (T[] layout ...);
        
                // insert before current selection
                MutableString prepend (T[] other);
                MutableString prepend (String other);
                MutableString prepend (T chr, int count=1);

                // replace current selection
                MutableString replace (T chr);
                MutableString replace (T[] other);
                MutableString replace (String other);

                // remove current selection
                MutableString remove ();

                // truncate at point, or current selection
                MutableString truncate (int point = int.max);

                // trim content
                MutableString trim ();

                // return content
                T[] aliasOf ();
        }

        class String(T) : UniString
        {
                // iterate across content
                opApply (int delegate(inout T) dg);

                // hash content
                uint toHash ();

                // return length of content
                uint length ();

                // compare content
                bool equals  (T[] other);
                bool equals  (String other);
                bool ends    (T[] other);
                bool ends    (String other);
                bool starts  (T[] other);
                bool starts  (String other);
                int compare  (T[] other);
                int compare  (String other);
                int opEquals (Object other);
                int opCmp    (Object other);

                // copy content
                T[] copy (T[] dst);
                T[] copy ();

                // replace the comparison algorithm 
                String setComparator (Comparator comparator);
        }

        abstract class UniString
        {
                // convert content
                abstract char[]  utf8  (char[]  dst = null);
                abstract wchar[] utf16 (wchar[] dst = null);
                abstract dchar[] utf32 (dchar[] dst = null);
        }
        ---

*******************************************************************************/

module tango.text.String;

private import  tango.text.Text;

private import  tango.convert.Type,
                tango.convert.Format,
                tango.convert.Unicode;

private import  tango.text.model.UniString;

/*******************************************************************************

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);


/*******************************************************************************

        MutableString is a string class that stores Unicode characters.

        Indexes and lengths of strings always count code units, not code 
        points. This is similar to traditional multi-byte string handling. 
        Operations on strings do not test for code point boundaries since
        the approach taken here is based upon pattern-matching rather than
        direct indexing.

        MutableString maintains a current "selection", controlled via the 
        select() and rselect() methods. Append(), prepend(), replace() and
        remove() each operate with respect to the selection. The select()
        methods themselves operate with respect to the current selection
        also, providing a means of iterating across matched patterns. To
        reset the selection to the entire string, use the select() method 
        with no arguments. 
       
*******************************************************************************/

class MutableStringT(T) : StringT!(T)
{
        public  alias append                    opCat;

        private alias FormatStructT!(T)         Format;
        private  alias Unicode.Into!(T)         Into;   

        public  Into                    into;           // unicode converter
        private T[]                     scratch;        // formatting scratchpad
        private T[]                     converts;       // unicode buffer
        private Format                  formatter;      // printf formatter


        /***********************************************************************
        
                Create an empty MutableString with the specified available 
                space

        ***********************************************************************/

        this (uint space = 0)
        {
                content.length = space;
                mutable = true;
                setup ();
        }

        /***********************************************************************
        
                Create a MutableString upon the provided content. If said 
                content is immutable (read-only) then you might consider 
                setting the 'mutable' parameter to false. Doing so will 
                avoid allocating heap-space for the content until it is 
                modified.

        ***********************************************************************/

        this (T[] content, bool mutable = true)
        {
                set (content, mutable);
                setup ();
        }

        /***********************************************************************
        
                Create a MutableString via the content of a MutableString. 
                If said content is immutable (read-only) then you might 
                consider setting the 'mutable' parameter to false. Doing 
                so will avoid allocating heap-space for the content until 
                it is modified via MutableString methods.

        ***********************************************************************/
        
        this (MutableStringT other, bool mutable = true)
        {
                this (other.get, mutable);
        }

        /***********************************************************************
        
                Create a MutableString via the content of a String. Note 
                that the default is to assume the content is immutable
                
        ***********************************************************************/
        
        this (StringT!(T) other, bool mutable = false)
        {
                this (other.get, mutable);
        }

        /***********************************************************************
   
                Set the content to the provided array. Parameter 'mutable'
                specifies whether the given array is likely to change. If 
                not, the array is aliased until such time it is altered.
                     
        ***********************************************************************/

        MutableStringT set (T[] chars, bool mutable = true)
        {
                contentLength = chars.length;
                select (0, contentLength);

                if ((this.mutable = mutable) == true)
                     content = chars.dup;
                else
                   content = chars;
                return this;
        }

        /***********************************************************************
        
                Replace the content of this MutableString. If the new content
                is immutable (read-only) then you might consider setting the
                'mutable' parameter to false. Doing so will avoid allocating
                heap-space for the content until it is modified via one of
                these methods.

        ***********************************************************************/

        MutableStringT set (StringT!(T) other, bool mutable = true)
        {
                return set (other.get, mutable);
        }

        /***********************************************************************

                Return the index and length of the current selection

        ***********************************************************************/

        uint selection (inout int length)
        {
                length = selectLength;
                return selectPoint;
        }

        /***********************************************************************

                Explicitly set the current selection

        ***********************************************************************/

        MutableStringT select (int start=0, int length=int.max)
        {
                pinIndices (start, length);
                selectPoint = start;
                selectLength = length;                
                return this;
        }

        /***********************************************************************
        
                Find the first occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        bool select (T c)
        {
                int x = utils.indexOf (get(), c, selectPoint);
                if (x >= 0)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find the first occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        bool select (StringT!(T) other)
        {
                return select (other.get);
        }

        /***********************************************************************
        
                Find the first occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        bool select (T[] chars)
        {
                int x = utils.indexOf (get(), chars, selectPoint);
                if (x >= 0)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find the last occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        bool rselect (T c)
        {
                int x = utils.rIndexOf (get(), c, selectPoint+selectLength);               
                if (x >= 0)
                   {
                   select (x, 1);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Find the last occurrence of a BMP code point in a string.
                A surrogate code point is found only if its match in the 
                text is not part of a surrogate pair.

        ***********************************************************************/

        bool rselect (StringT!(T) other)
        {
                return rselect (other.get);
        }

        /***********************************************************************
        
                Find the last occurrence of a substring in a string. 

                The substring is found at code point boundaries. That means 
                that if the substring begins with a trail surrogate or ends 
                with a lead surrogate, then it is found only if these 
                surrogates stand alone in the text. Otherwise, the substring 
                edge units would be matched against halves of surrogate pairs.

        ***********************************************************************/

        bool rselect (T[] chars)
        {
                int x = utils.rIndexOf (get(), chars, selectPoint+selectLength);
                if (x >= 0)
                   {
                   select (x, chars.length);
                   return true;
                   }
                return false;
        }

        /***********************************************************************
        
                Append partial text to this MutableString

        ***********************************************************************/

        MutableStringT append (StringT!(T) other)
        {
                return append (other.get);
        }

        /***********************************************************************
        
                Append text to this MutableString

        ***********************************************************************/

        MutableStringT append (char[] chars)
        {
                convert (chars, Type.Utf8);
                return this;
        }

        /***********************************************************************
        
                Append text to this MutableString

        ***********************************************************************/

        MutableStringT append (wchar[] chars)
        {
                convert (chars, Type.Utf16);
                return this;
        }

        /***********************************************************************
        
                Append text to this MutableString

        ***********************************************************************/

        MutableStringT append (dchar[] chars)
        {
                convert (chars, Type.Utf32);
                return this;
        }

        /***********************************************************************
        
                Append a count of characters to this MutableString

        ***********************************************************************/

        MutableStringT append (T chr, int count=1)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                return set (chr, point, count);
        }

        /***********************************************************************
        
                Append an integer to this MutableString, using standard 
                printf() notation

        ***********************************************************************/

        MutableStringT append (int v, T[] format=null)
        {
                formatter (format, &v, v.sizeof, Type.Int);
                return this;
        }

        /***********************************************************************
        
                Append a long to this MutableString, using standard 
                printf() notation

        ***********************************************************************/

        MutableStringT append (long v, T[] format=null)
        {
                formatter (format, &v, v.sizeof, Type.Long);
                return this;
        }

        /***********************************************************************
        
                Append a double to this MutableString, using standard 
                printf() notation

        ***********************************************************************/

        MutableStringT append (double v, T[] format=null)
        {
                formatter (format, &v, v.sizeof, Type.Double);
                return this;
        }

        /**********************************************************************

                Format a set of arguments using the standard printf()
                formatting notation

        **********************************************************************/

        MutableStringT format (T[] fmt, ...)
        {
                formatter (fmt, _arguments, _argptr);
                return this;
        }

        /***********************************************************************
        
                Insert characters into this MutableString

        ***********************************************************************/

        MutableStringT prepend (T chr, uint count=1)
        {
                expand (selectPoint, count);
                return set (chr, selectPoint, count);
        }

        /***********************************************************************
        
                Insert text into this MutableString

        ***********************************************************************/

        MutableStringT prepend (T[] other)
        {
                expand (selectPoint, other.length);
                content[selectPoint..selectPoint+other.length] = other;
                return this;
        }

        /***********************************************************************
        
                Insert another String into this MutableString

        ***********************************************************************/

        MutableStringT prepend (StringT!(T) other)
        {       
                return prepend (other.get);
        }

        /***********************************************************************
                
                Replace a section of this MutableString with the specified 
                character

        ***********************************************************************/

        MutableStringT replace (T chr)
        {
                return set (chr, selectPoint, selectLength);
        }

        /***********************************************************************
                
                Replace a section of this MutableString with the specified 
                array

        ***********************************************************************/

        MutableStringT replace (T[] chars)
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
                
                Replace a section of this MutableString with the specified 
                String

        ***********************************************************************/

        MutableStringT replace (StringT!(T) other)
        {
                return replace (other.get);
        }

        /***********************************************************************
        
                Remove the selection from this MutableString and reset the
                selection to zero length

        ***********************************************************************/

        MutableStringT remove ()
        {
                remove (selectLength);
                select (selectPoint, 0);
                return this;
        }

        /***********************************************************************
        
                Remove the selection from this MutableString and reset the
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
                the current append point

        ***********************************************************************/

        MutableStringT truncate (int index = int.max)
        {
                if (index is int.max)
                    index = selectPoint + selectLength;

                pinIndex (index);
                contentLength = index;
                return this;
        }

        /**********************************************************************

                Arranges text strings in order, using indices to specify 
                where each particular argument should be positioned within 
                the text. This is handy for collating I18N components.

                ---
                auto string = new MutableString;

                string.layout ("%2 %1", "one", "two");
                ---

                The index numbers range from one through nine      
              
        **********************************************************************/

        MutableStringT layout (T[][] layout ...)
        {
                int     args;
                bool    state;

                args = layout.length - 1;
                foreach (T c; layout[0])
                        {
                        if (state)
                           {
                           state = false;
                           if (c >= '1' || c <= '9')
                              {
                              uint index = c - '0';
                              if (index <= args)
                                 {
                                 append (layout[index]);
                                 continue;
                                 }
                              else
                                 formatter.error ("TextLayout : invalid argument");
                              }
                           }
                        else
                           if (c == '%')
                              {
                              state = true;
                              continue;
                              }
                        append (c);
                        }
                return this;
        }

        /***********************************************************************
        
                Remove leading and trailing whitespace from this String,
                and reset the selection to the trimmed content

        ***********************************************************************/

        MutableStringT trim ()
        {
                content = utils.trim (get());
                select (0, contentLength = content.length);
                return this;
        }

        /***********************************************************************
        
                Return an alias to the content of this MutableString

        ***********************************************************************/

        T[] aliasOf ()
        {
                return get ();
        }


        /* ================================================================== */


        /***********************************************************************
        
                make room available to insert or append something

        ***********************************************************************/

        private final void expand (uint index, uint count)
        {
                if (!mutable || (contentLength + count) > content.length)
                     realloc (count);

                memmove (content.ptr+index+count, content.ptr+index, (contentLength - index) * T.sizeof);
                selectLength += count;
                contentLength += count;                
        }
                
        /***********************************************************************
                
                Replace a section of this MutableString with the specified 
                character

        ***********************************************************************/

        private final MutableStringT set (T chr, uint start, uint count)
        {
                content [start..start+count] = chr;
                return this;
        }

        /***********************************************************************
        
                Allocate memory due to a change in the content. We handle 
                the distinction between mutable and immutable here.

        ***********************************************************************/

        private final void realloc (uint count = 0)
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
        
                Internal method to support MutableString appending

        ***********************************************************************/

        private final MutableStringT append (T* chars, uint count)
        {
                uint point = selectPoint + selectLength;
                expand (point, count);
                content[point .. point+count] = chars[0 .. count];
                return this;
        }

        /***********************************************************************
        
                Initialize this MutableString. Allocate conversion buffers
                and prime the formatter

        ***********************************************************************/

        private void setup (Format.DblFormat df = null)
        {
                
                scratch  = new T[64];
                converts = new T[256];
                formatter.ctor (&convert, scratch, df);                
        }

        /**********************************************************************

                Support for the formatter, to convert from one encoding
                to another

        **********************************************************************/

        private uint convert (void[] v, uint type)   
        {
                // convert as required
                auto s = cast(T[]) into.convert (v, type, converts);
                        
                // hang onto conversion buffer when it grows
                if (s.length > converts.length)
                    converts = s;

                // append to string
                append (s.ptr, s.length);
                return s.length;
        }
}



/*******************************************************************************

        Immutable string

*******************************************************************************/

class StringT(T) : UniString
{
        public alias int delegate (T[] a, T[] b) Comparator;
        public alias get                opIndex;

        // unicode converter and utility functions
        public Unicode.From!(T)         from;
        public TextT!(T)                utils;

        // the core of the String and MutableString attributes. The name 
        // 'contentLength' is used rather than the more obvious 'length' 
        // since there is a collision with the noxious array[length] sugar
        protected T[]                   content;
        protected uint                  selectPoint,
                                        selectLength,
                                        contentLength;

        // this should probably be in MutableString only, but there seems to 
        // be a compiler bug where it doesn't get initialised correctly,
        // and it's perhaps useful to have here for when a MutableString is
        // passed as a String argument.
        protected bool                  mutable;
        
        private Comparator              comparator;

        /***********************************************************************
        
                Hidden constructor

        ***********************************************************************/

        private this ()
        {
                this.comparator = &simpleComparator;
        }

        /***********************************************************************
        
                Construct read-only wrapper around the given content

        ***********************************************************************/

        this (T[] content)
        {
                this();
                this.content = content;
                this.selectPoint = 0;
                this.selectLength = this.contentLength = content.length;
        }

        /***********************************************************************
        
                Get the encoding type

        ***********************************************************************/	

	uint getEncoding()
	{
		static if( is( T == char ))
			return Type.Utf8;
		else static if( is( T == wchar ))
			return Type.Utf16;
		else static if( is( T == dchar ))
			return Type.Utf32;
	}

        /***********************************************************************
        
                Set the comparator delegate

        ***********************************************************************/

        StringT setComparator (Comparator comparator)
        {
                this.comparator = comparator;
                return this;
        }

        /***********************************************************************
        
                Hash this String

        ***********************************************************************/

        override uint toHash ()
        {
                return hash (content [0 .. contentLength]);
        }

        /***********************************************************************
        
                Return the length of the valid content

        ***********************************************************************/

        uint length ()
        {
                return contentLength;
        }

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        bool equals (StringT other)
        {
                if (other is this)
                    return true;
                return equals (other.get);
        }

        /***********************************************************************
        
                Is this String equal to the the provided text?

        ***********************************************************************/

        bool equals (T[] other)
        {
                if (other.length == contentLength)
                    return utils.equal (other.ptr, content.ptr, contentLength);
                return false;
        }

        /***********************************************************************
        
                Does this String end with another?

        ***********************************************************************/

        bool ends (StringT other)
        {
                return ends (other.get);
        }

        /***********************************************************************
        
                Does this String end with the specified string?

        ***********************************************************************/

        bool ends (T[] chars)
        {
                if (chars.length <= contentLength)
                    return utils.equal (content.ptr+(contentLength-chars.length), chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************
        
                Does this String start with another?

        ***********************************************************************/

        bool starts (StringT other)
        {
                return starts (other.get);
        }

        /***********************************************************************
        
                Does this String start with the specified string?

        ***********************************************************************/

        bool starts (T[] chars)
        {
                if (chars.length <= contentLength)                
                    return utils.equal (content.ptr, chars.ptr, chars.length);
                return false;
        }

        /***********************************************************************
        
                Compare this String start with another. Returns 0 if the 
                content matches, less than zero if this String is "less"
                than the other, or greater than zero where this String 
                is "bigger".

        ***********************************************************************/

        int compare (StringT other)
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

        int compare (T[] chars)
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

        T[] copy (T[] dst)
        {
                uint i = contentLength;
                if (i > dst.length)
                    i = dst.length;

                return dst [0 .. i] = content [0 .. i];
        }

        /***********************************************************************
        
                Return dup'd content from this String 

        ***********************************************************************/

        T[] copy ()
        {
                return content [0 .. contentLength].dup;
        }

        /***********************************************************************

                Convert to the AbstractString types. The optional argument
                dst will be resized as required to house the conversion. 
                To minimize heap allocation, use the following pattern:

                        String  string;

                        wchar[] buffer;
                        wchar[] result = string.toUtf16 (buffer);

                        if (result.length > buffer.length)
                            buffer = result;

               You can also provide a buffer from the stack, but the output 
               will be moved to the heap if said buffer is not large enough

        ***********************************************************************/

        char[] utf8 (char[] dst = null)
        {
                return cast(char[]) from.convert (get(), Type.Utf8, dst);
        }

        wchar[] utf16 (wchar[] dst = null)
        {
                return cast(wchar[]) from.convert (get(), Type.Utf16, dst);
        }

        dchar[] utf32 (dchar[] dst = null)
        {
                return cast(dchar[]) from.convert (get(), Type.Utf32, dst);
        }

        /**********************************************************************

                Iterate over the characters in this string. Note that 
                this is a read-only freachable ~ the worst a user can
                do is alter the temporary 'c'

        **********************************************************************/

        int opApply (int delegate(inout T) dg)
        {
                int result = 0;

                foreach (T c; get())
                         if ((result = dg (c)) != 0)
                             break;
                return result;
        }

        /***********************************************************************
        
                Compare this String to another

        ***********************************************************************/

        final override int opCmp (Object o)
        {
                auto other = cast (StringT) o;

                if (other is null)
                    return -1;

                return compare (other);
        }

        /***********************************************************************
        
                Is this String equal to another?

        ***********************************************************************/

        final override int opEquals (Object o)
        {
                auto other = cast (StringT) o;

                if (other is null)
                    return 0;

                return equals (other);
        }

        /**********************************************************************

            hash() -- hash a variable-length key into a 32-bit value

              k     : the key (the unaligned variable-length array of bytes)
              len   : the length of the key, counting by bytes
              level : can be any 4-byte value

            Returns a 32-bit value.  Every bit of the key affects every bit of
            the return value.  Every 1-bit and 2-bit delta achieves avalanche.

            About 4.3*len + 80 X86 instructions, with excellent pipelining

            The best hash table sizes are powers of 2.  There is no need to do
            mod a prime (mod is sooo slow!).  If you need less than 32 bits,
            use a bitmask.  For example, if you need only 10 bits, do

                        h = (h & hashmask(10));

            In which case, the hash table should have hashsize(10) elements.
            If you are hashing n strings (ub1 **)k, do it like this:

                        for (i=0, h=0; i<n; ++i) h = hash( k[i], len[i], h);

            By Bob Jenkins, 1996.  bob_jenkins@burtleburtle.net.  You may use 
            this code any way you wish, private, educational, or commercial.  
            It's free.
            
            See http://burlteburtle.net/bob/hash/evahash.html
            Use for hash table lookup, or anything where one collision in 2^32 
            is acceptable. Do NOT use for cryptographic purposes.

        **********************************************************************/

        static final uint hash (void[] x, uint c = 0)
        {
            uint    a,
                    b;

            a = b = 0x9e3779b9; 

            uint len = x.length;
            ubyte* k = cast(ubyte *) x.ptr;

            // handle most of the key 
            while (len >= 12) 
                  {
                  a += *cast(uint *)(k+0);
                  b += *cast(uint *)(k+4);
                  c += *cast(uint *)(k+8);

                  a -= b; a -= c; a ^= (c>>13); 
                  b -= c; b -= a; b ^= (a<<8); 
                  c -= a; c -= b; c ^= (b>>13); 
                  a -= b; a -= c; a ^= (c>>12);  
                  b -= c; b -= a; b ^= (a<<16); 
                  c -= a; c -= b; c ^= (b>>5); 
                  a -= b; a -= c; a ^= (c>>3);  
                  b -= c; b -= a; b ^= (a<<10); 
                  c -= a; c -= b; c ^= (b>>15); 
                  k += 12; len -= 12;
                  }

            // handle the last 11 bytes 
            c += x.length;
            switch (len)
                   {
                   case 11: c+=(cast(uint)k[10]<<24);
                   case 10: c+=(cast(uint)k[9]<<16);
                   case 9 : c+=(cast(uint)k[8]<<8);
                   case 8 : b+=(cast(uint)k[7]<<24);
                   case 7 : b+=(cast(uint)k[6]<<16);
                   case 6 : b+=(cast(uint)k[5]<<8);
                   case 5 : b+=k[4];
                   case 4 : a+=(cast(uint)k[3]<<24);
                   case 3 : a+=(cast(uint)k[2]<<16);
                   case 2 : a+=(cast(uint)k[1]<<8);
                   case 1 : a+=k[0];
                   default:
                   }

            a -= b; a -= c; a ^= (c>>13); 
            b -= c; b -= a; b ^= (a<<8); 
            c -= a; c -= b; c ^= (b>>13); 
            a -= b; a -= c; a ^= (c>>12);  
            b -= c; b -= a; b ^= (a<<16); 
            c -= a; c -= b; c ^= (b>>5); 
            a -= b; a -= c; a ^= (c>>3);  
            b -= c; b -= a; b ^= (a<<10); 
            c -= a; c -= b; c ^= (b>>15); 

            return c;
        }

        /***********************************************************************
        
                Throw an exception

        ***********************************************************************/

        protected final void error (char[] msg)
        {
                static class TextException : Exception
                {
                        this (char[] msg)
                        {
                                super (msg);
                        }
                }

                throw new TextException (msg);
        }

        /***********************************************************************
        
                Return the valid content from this String

        ***********************************************************************/

        package final T[] get ()
        {
                    return content [0 .. contentLength];
        }

        /***********************************************************************
        
                Pin the given index to a valid position.

        ***********************************************************************/

        protected final void pinIndex (inout int x)
        {
                if (x > contentLength)
                    x = contentLength;
        }

        /***********************************************************************
        
                Pin the given index and length to a valid position.

        ***********************************************************************/

        protected final void pinIndices (inout int start, inout int length)
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

        protected final int simpleComparator (T[] a, T[] b)
        {
                uint i = a.length;
                if (b.length < i)
                    i = b.length;

                for (int j, k; j < i; ++j)
                     if ((k = a[j] - b[j]) != 0)
                          return k;
                
                return a.length - b.length;
        }
}       


// convenience alias
alias StringT!(char) String;

// convenience alias
alias MutableStringT!(char) MutableString;

