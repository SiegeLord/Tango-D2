/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2004: Initial release
                        Dec 2006: South Seas version

        author:         Kris


        Placeholder for a variety of wee functions. These functions are all
        templated with the intent of being used for arrays of char, wchar,
        and dchar. However, they operate correctly with other array types
        also.

        Several of these functions return an index value, representing where
        some criteria was identified. When said criteria is not matched, the
        functions return a value representing the array length provided to
        them. That is, for those scenarios where C functions might typically
        return -1 these functions return length instead. This operate nicely
        with D slices:
        ---
        auto text = "happy:faces";
        
        assert (text[0 .. locate (text, ':')] == "happy");
        
        assert (text[0 .. locate (text, '!')] == "happy:faces");
        ---

        The contains() function is more convenient for trivial lookup
        cases:
        ---
        if (contains ("fubar", '!'))
            ...
        ---

        Note that where some functions expect a size_t as an argument, the
        D template-matching algorithm will fail where an int is provided
        instead. This is the typically the cause of "template not found"
        errors. Also note that name overloading is not supported cleanly
        by IFTI at this time, so is not applied here.


        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import Util = tango.text.Util;

        auto s = Util.trim ("  foo ");
        ---
                

        Function templates:
        ---
        trim (source)                               // trim whitespace
        triml (source)                              // trim whitespace
        trimr (source)                              // trim whitespace
        strip (source, match)                       // trim elements
        stripl (source, match)                      // trim elements
        stripr (source, match)                      // trim elements
        chopl (source, match)                       // trim pattern match
        chopr (source, match)                       // trim pattern match
        delimit (src, set)                          // split on delims
        split (source, pattern)                     // split on pattern
        splitLines (source);                        // split on lines
        head (source, pattern, tail)                // split to head & tail
        join (source, postfix, output)              // join text segments
        prefix (dst, prefix, content...)            // prefix text segments
        postfix (dst, postfix, content...)          // postfix text segments
        combine (dst, prefix, postfix, content...)  // combine lotsa stuff
        repeat (source, count, output)              // repeat source 
        replace (source, match, replacement)        // replace chars
        substitute (source, match, replacement)     // replace/remove matches
        count (source, match)                       // count instances
        contains (source, match)                    // has char?
        containsPattern (source, match)             // has pattern?
        index (source, match, start)                // find match index
        locate (source, match, start)               // find char
        locatePrior (source, match, start)          // find prior char
        locatePattern (source, match, start);       // find pattern
        locatePatternPrior (source, match, start);  // find prior pattern
        indexOf (s*, match, length)                 // low-level lookup
        mismatch (s1*, s2*, length)                 // low-level compare
        matching (s1*, s2*, length)                 // low-level compare
        isSpace (match)                             // is whitespace?
        unescape(source, output)                    // convert '\' prefixes
        layout (destination, format ...)            // featherweight printf
        lines (str)                                 // foreach lines
        quotes (str, set)                           // foreach quotes
        delimiters (str, set)                       // foreach delimiters
        patterns (str, pattern)                     // foreach patterns
        ---

        Please note that any 'pattern' referred to within this module
        refers to a pattern of characters, and not some kind of regex
        descriptor. Use the Regex module for regex operation.

*******************************************************************************/

module tango.text.Util;

/******************************************************************************

        Trim the provided array by stripping whitespace from both
        ends. Returns a slice of the original content

******************************************************************************/


T[] trim(T) (T[] source)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (head < tail && isSpace(*head))
               ++head;

        while (tail > head && isSpace(*(tail-1)))
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the provided array by stripping whitespace from the left.
        Returns a slice of the original content

******************************************************************************/

T[] triml(T) (T[] source)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (head < tail && isSpace(*head))
               ++head;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the provided array by stripping whitespace from the right.
        Returns a slice of the original content

******************************************************************************/

T[] trimr(T) (T[] source)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (tail > head && isSpace(*(tail-1)))
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the given array by stripping the provided match from
        both ends. Returns a slice of the original content

******************************************************************************/

T[] strip(T, S) (T[] source, S match)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (head < tail && *head is match)
               ++head;

        while (tail > head && *(tail-1) is match)
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the given array by stripping the provided match from
        the left hand side. Returns a slice of the original content

******************************************************************************/

T[] stripl(T, S) (T[] source, S match)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (head < tail && *head is match)
               ++head;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the given array by stripping the provided match from
        the right hand side. Returns a slice of the original content

******************************************************************************/

T[] stripr(T, S) (T[] source, S match)
{
        auto head = source.ptr;
        auto tail = head + source.length;

        while (tail > head && *(tail-1) is match)
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Chop the given source by stripping the provided match from
        the left hand side. Returns a slice of the original content

******************************************************************************/

T[] chopl(T, S) (T[] source, S match)
{
        if (match.length <= source.length)
            if (source[0 .. match.length] == match)
                source = source [match.length .. $];

        return source;
}

/******************************************************************************

        Chop the given source by stripping the provided match from
        the right hand side. Returns a slice of the original content

******************************************************************************/

T[] chopr(T, S) (T[] source, S match)
{
        if (match.length <= source.length)
            if (source[$-match.length .. $] == match)
                source = source [0 .. $-match.length];

        return source;
}

/******************************************************************************

        Replace all instances of one element with another (in place)

******************************************************************************/

T[] replace(T, S) (T[] source, S match, S replacement)
{
        foreach (ref c; source)
                 if (c is match)
                     c = replacement;
        return source;
}

/******************************************************************************

        Substitute all instances of match from source. Set replacement
        to null in order to remove instead of replace

******************************************************************************/

T[] substitute(T) (const(T)[] source, const(T)[] match, const(T)[] replacement)
{
        T[] output;

        foreach (s; patterns (source, match, replacement))
                    output ~= s;
        return output;
}

/******************************************************************************

        Count all instances of match within source 

******************************************************************************/

size_t count(T) (const(T)[] source, const(T)[] match)
{
        size_t c;

        foreach (s; patterns (source, match))
                    ++c;
        assert(c > 0);
        return c - 1;
}

/******************************************************************************

        Returns whether or not the provided array contains an instance
        of the given match
        
******************************************************************************/

bool contains(T) (const(T)[] source, const(T) match)
{
        return indexOf (source.ptr, match, source.length) != source.length;
}

/******************************************************************************

        Returns whether or not the provided array contains an instance
        of the given match
        
******************************************************************************/

bool containsPattern(T) (const(T)[] source, const(T)[] match)
{
        return locatePattern (source, match) != source.length;
}

/******************************************************************************

        Return the index of the next instance of 'match' starting at
        position 'start', or source.length where there is no match.

        Parameter 'start' defaults to 0

******************************************************************************/

size_t index(T, U=size_t) (const(T)[] source, const(T)[] match, U start=0)
{return index!(T) (source, match, start);}

size_t index(T) (const(T)[] source, const(T)[] match, size_t start=0)
{
        return (match.length is 1) ? locate (source, match[0], start) 
                                   : locatePattern (source, match, start);
}

/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or source.length where there is no match.

        Parameter 'start' defaults to source.length

******************************************************************************/

size_t rindex(T, U=size_t) (const(T)[] source, const(T)[] match, U start=U.max)
{return rindex!(T)(source, match, start);}

size_t rindex(T) (const(T)[] source, const(T)[] match, size_t start=size_t.max)
{
        return (match.length is 1) ? locatePrior (source, match[0], start) 
                                   : locatePatternPrior (source, match, start);
}

/******************************************************************************

        Return the index of the next instance of 'match' starting at
        position 'start', or source.length where there is no match.

        Parameter 'start' defaults to 0

******************************************************************************/

size_t locate(T, U=size_t) (const(T)[] source, const(T) match, U start=0)
{return locate!(T) (source, match, start);}

size_t locate(T) (const(T)[] source, const(T) match, size_t start=0)
{
        if (start > source.length)
            start = source.length;
        
        return indexOf (source.ptr+start, match, source.length - start) + start;
}

/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or source.length where there is no match.

        Parameter 'start' defaults to source.length

******************************************************************************/

size_t locatePrior(T, U=size_t) (const(T)[] source, const(T) match, U start=U.max)
{return locatePrior!(T)(source, match, start);}

size_t locatePrior(T) (const(T)[] source, const(T) match, size_t start=size_t.max)
{
        if (start > source.length)
            start = source.length;

        while (start > 0)
               if (source[--start] is match)
                   return start;
        return source.length;
}

/******************************************************************************

        Return the index of the next instance of 'match' starting at
        position 'start', or source.length where there is no match. 

        Parameter 'start' defaults to 0

******************************************************************************/

size_t locatePattern(T, U=size_t) (const(T)[] source, const(T)[] match, U start=0)
{return locatePattern!(T) (source, match, start);}

size_t locatePattern(T) (const(T)[] source, const(T)[] match, size_t start=0)
{
        size_t    idx;
        const(T)* p = source.ptr + start;
        size_t    extent = source.length - start - match.length + 1;

        if (match.length && extent <= source.length)
            {
            while (extent)
                   if ((idx = indexOf (p, match[0], extent)) is extent)
                        break;
                   else
                      if (matching (p+=idx, match.ptr, match.length))
                          return p - source.ptr;
                      else
                         {
                         extent -= (idx+1);
                         ++p;
                         }
            }
        return source.length;
}
   
/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or source.length where there is no match.

        Parameter 'start' defaults to source.length

******************************************************************************/

size_t locatePatternPrior(T, U=size_t) (const(T)[] source, const(T)[] match, U start=U.max)
{return locatePatternPrior!(T)(source, match, start);}

size_t locatePatternPrior(T) (const(T)[] source, const(T)[] match, size_t start=size_t.max)
{
        auto len = source.length;
        
        if (start > len)
            start = len;

        if (match.length && match.length <= len)
            while (start)
                  {
                  start = locatePrior (source, match[0], start);
                  if (start is len)
                      break;
                  else
                     if ((start + match.length) <= len)
                          if (matching (source.ptr+start, match.ptr, match.length))
                              return start;
                  }

        return len;
}

/******************************************************************************

        Split the provided array on the first pattern instance, and 
        return the resultant head and tail. The pattern is excluded 
        from the two segments. 

        Where a segment is not found, tail will be null and the return
        value will be the original array.
        
******************************************************************************/

T[] head(T, S) (T[] src, S[] pattern, out T[] tail)
{
        auto i = locatePattern (src, pattern);
        if (i != src.length)
           {
           tail = src [i + pattern.length .. $];
           src = src [0 .. i];
           }
        return src;
}

/******************************************************************************

        Split the provided array on the last pattern instance, and 
        return the resultant head and tail. The pattern is excluded 
        from the two segments. 

        Where a segment is not found, head will be null and the return
        value will be the original array.
        
******************************************************************************/

T[] tail(T, S) (T[] src, S[] pattern, out T[] head)
{
        auto i = locatePatternPrior (src, pattern);
        if (i != src.length)
           {
           head = src [0 .. i];
           src = src [i + pattern.length .. $];
           }
        return src;
}

/******************************************************************************

        Split the provided array wherever a delimiter-set instance is
        found, and return the resultant segments. The delimiters are
        excluded from each of the segments. Note that delimiters are
        matched as a set of alternates rather than as a pattern.

        Splitting on a single delimiter is considerably faster than
        splitting upon a set of alternatives. 

        Note that the src content is not duplicated by this function, 
        but is sliced instead.

******************************************************************************/

T[][] delimit(T, M) (T[] src, const(M)[] set)
{
        T[][] result;

        foreach (segment; delimiters (src, set))
                 result ~= segment;
        return result;
}

/******************************************************************************

        Split the provided array wherever a pattern instance is
        found, and return the resultant segments. The pattern is
        excluded from each of the segments.
        
        Note that the src content is not duplicated by this function, 
        but is sliced instead.

******************************************************************************/

inout(T)[][] split(T) (inout(T)[] src, const(T)[] pattern)
{
        const(T)[][] result;

        foreach (segment; patterns (cast(const(T)[])src, pattern))
                 result ~= segment;
        return cast(inout(T)[][])result;
}

/******************************************************************************

        Convert text into a set of lines, where each line is identified
        by a \n or \r\n combination. The line terminator is stripped from
        each resultant array

        Note that the src content is not duplicated by this function, but
        is sliced instead.

******************************************************************************/

alias toLines splitLines;
T[][] toLines(T) (T[] src)
{

        T[][] result;

        foreach (line; lines (src))
                 result ~= line;
        return result;
}

/******************************************************************************

        Return the indexed line, where each line is identified by a \n 
        or \r\n combination. The line terminator is stripped from the 
        resultant line

        Note that src content is not duplicated by this function, but
        is sliced instead.

******************************************************************************/

T[] lineOf(T) (T[] src, size_t index)
{
        int i = 0;
        foreach (line; lines (src))
                 if (i++ is index)
                     return line;
        return null;
}

/******************************************************************************

        Combine a series of text segments together, each appended with 
        a postfix pattern. An optional output buffer can be provided to
        avoid heap activity - it should be large enough to contain the 
        entire output, otherwise the heap will be used instead.

        Returns a valid slice of the output, containing the concatenated
        text.

******************************************************************************/

T[] join(T) (const(T)[][] src, const(T)[] postfix=null, T[] dst=null)
{
        return combine!(T) (dst, null, postfix, src);
}

/******************************************************************************

        Combine a series of text segments together, each prepended with 
        a prefix pattern. An optional output buffer can be provided to 
        avoid heap activity - it should be large enough to contain the 
        entire output, otherwise the heap will be used instead.

        Note that, unlike join(), the output buffer is specified first
        such that a set of trailing strings can be provided. 

        Returns a valid slice of the output, containing the concatenated
        text.

******************************************************************************/

T[] prefix(T) (T[] dst, const(T)[] prefix, const(T)[][] src...)
{
        return combine!(T) (dst, prefix, null, src);
}

/******************************************************************************

        Combine a series of text segments together, each appended with an 
        optional postfix pattern. An optional output buffer can be provided
        to avoid heap activity - it should be large enough to contain the 
        entire output, otherwise the heap will be used instead.

        Note that, unlike join(), the output buffer is specified first
        such that a set of trailing strings can be provided. 

        Returns a valid slice of the output, containing the concatenated
        text.

******************************************************************************/

T[] postfix(T) (T[] dst, const(T)[] postfix, const(T)[][] src...)
{
        return combine!(T) (dst, null, postfix, src);
}

/******************************************************************************

        Combine a series of text segments together, each prefixed and/or 
        postfixed with optional strings. An optional output buffer can be 
        provided to avoid heap activity - which should be large enough to 
        contain the entire output, otherwise the heap will be used instead.

        Note that, unlike join(), the output buffer is specified first
        such that a set of trailing strings can be provided. 

        Returns a valid slice of the output, containing the concatenated
        text.

******************************************************************************/

T[] combine(T) (T[] dst, const(T)[] prefix, const(T)[] postfix, const(T)[][] src ...)
{
        size_t len = src.length * prefix.length + 
                   src.length * postfix.length;

        foreach (segment; src)
                 len += segment.length;
               
        if (dst.length < len)
            dst.length = len;
            
        T* p = dst.ptr;
        foreach (segment; src)
                {
                p[0 .. prefix.length] = prefix;
                p += prefix.length;
                p[0 .. segment.length] = segment;
                p += segment.length;
                p[0 .. postfix.length] = postfix;
                p += postfix.length;
                }

        // remove trailing seperator
        if (len)
            len -= postfix.length;
        return dst [0 .. len];       
}

/******************************************************************************

        Repeat an array for a specific number of times. An optional output 
        buffer can be provided to avoid heap activity - it should be large 
        enough to contain the entire output, otherwise the heap will be used 
        instead.

        Returns a valid slice of the output, containing the concatenated
        text.

******************************************************************************/

T[] repeat(T, U=size_t) (const(T)[] src, U count, T[] dst=null)
{return repeat!(T)(src, count, dst);}

T[] repeat(T) (const(T)[] src, size_t count, T[] dst=null)
{
        size_t len = src.length * count;
        if (len is 0)
            return null;

        if (dst.length < len)
            dst.length = len;
            
        for (auto p = dst.ptr; count--; p += src.length)
             p[0 .. src.length] = src;

        return dst [0 .. len];
}

/******************************************************************************

        Is the argument a whitespace character?

******************************************************************************/

bool isSpace(T) (T c)
{
        static if (T.sizeof is 1)
                   return (c <= 32 && (c is ' ' || c is '\t' || c is '\r' || c is '\n' || c is '\f' || c is '\v'));
        else
           return (c <= 32 && (c is ' ' || c is '\t' || c is '\r' || c is '\n' || c is '\f' || c is '\v')) || (c is '\u2028' || c is '\u2029');
}

/******************************************************************************

        Return whether or not the two arrays have matching content
        
******************************************************************************/

bool matching(T, U=size_t) (const(T)* s1, const(T)* s2, U length)
{return matching!(T) (s1, s2, length);}

bool matching(T) (const(T)* s1, const(T)* s2, size_t length)
{
        return mismatch(s1, s2, length) is length;
}

/******************************************************************************

        Returns the index of the first match in str, failing once
        length is reached. Note that we return 'length' for failure
        and a 0-based index on success

******************************************************************************/

size_t indexOf(T, U=size_t) (const(T)* str, const(T) match, U length)
{return indexOf!(T) (str, match, length);}

size_t indexOf(T) (const(T)* str, const(T) match, size_t length)
{
        //assert (str);

        static if (T.sizeof == 1)
                   enum : size_t {m1 = cast(size_t) 0x0101010101010101, 
                                  m2 = cast(size_t) 0x8080808080808080}
        static if (T.sizeof == 2)
                   enum : size_t {m1 = cast(size_t) 0x0001000100010001, 
                                  m2 = cast(size_t) 0x8000800080008000}
        static if (T.sizeof == 4)
                   enum : size_t {m1 = cast(size_t) 0x0000000100000001, 
                                  m2 = cast(size_t) 0x8000000080000000}

        static if (T.sizeof < size_t.sizeof)
        {
                if (length)
                   {
                   size_t m = match;
                   m += m << (8 * T.sizeof);

                   static if (T.sizeof < size_t.sizeof / 2)
                              m += (m << (8 * T.sizeof * 2));

                   static if (T.sizeof < size_t.sizeof / 4)
                              m += (m << (8 * T.sizeof * 4));

                   auto p = str;
                   auto e = p + length - size_t.sizeof/T.sizeof;
                   while (p < e)
                         {
                         // clear matching T segments
                         auto v = (*cast(size_t*) p) ^ m;
                         // test for zero, courtesy of Alan Mycroft
                         if ((v - m1) & ~v & m2)
                              break;
                         p += size_t.sizeof/T.sizeof;
                         }

                   e += size_t.sizeof/T.sizeof;
                   while (p < e)
                          if (*p++ is match)
                              return cast(size_t) (p - str - 1);
                   }
                return length;
        }
        else
        {
                auto len = length;
                for (auto p=str-1; len--;)
                     if (*++p is match)
                         return cast(size_t) (p - str);
                return length;
        }
}

/******************************************************************************

        Returns the index of a mismatch between s1 & s2, failing when
        length is reached. Note that we return 'length' upon failure
        (array content matches) and a 0-based index upon success.

        Use this as a faster opEquals. Also provides the basis for a
        faster opCmp, since the index of the first mismatched character
        can be used to determine the return value

******************************************************************************/

size_t mismatch(T, U=size_t) (const(T)* s1, const(T)* s2, U length)
{return mismatch!(T)(s1, s2, length);}

size_t mismatch(T) (const(T)* s1, const(T)* s2, size_t length)
{
        assert (s1 && s2);

        static if (T.sizeof < size_t.sizeof)
        {
                if (length)
                   {
                   auto start = s1;
                   auto e = start + length - size_t.sizeof/T.sizeof;

                   while (s1 < e)
                         {
                         if (*cast(size_t*) s1 != *cast(size_t*) s2)
                             break;
                         s1 += size_t.sizeof/T.sizeof;
                         s2 += size_t.sizeof/T.sizeof;
                         }

                   e += size_t.sizeof/T.sizeof;
                   while (s1 < e)
                          if (*s1++ != *s2++)
                              return s1 - start - 1;
                   }
                return length;
        }
        else
        {
                auto len = length;
                for (auto p=s1-1; len--;)
                     if (*++p != *s2++)
                         return p - s1;
                return length;
        }
}

/******************************************************************************

        Iterator to isolate lines.

        Converts text into a set of lines, where each line is identified
        by a \n or \r\n combination. The line terminator is stripped from
        each resultant array.

        ---
        foreach (line; lines ("one\ntwo\nthree"))
                 ...
        ---
        
******************************************************************************/

LineFruct!(T) lines(T) (T[] src)
{
        LineFruct!(T) lines;
        lines.src = src;
        return lines;
}

/******************************************************************************

        Iterator to isolate text elements.

        Splits the provided array wherever a delimiter-set instance is
        found, and return the resultant segments. The delimiters are
        excluded from each of the segments. Note that delimiters are
        matched as a set of alternates rather than as a pattern.

        Splitting on a single delimiter is considerably faster than
        splitting upon a set of alternatives.

        ---
        foreach (segment; delimiters ("one,two;three", ",;"))
                 ...
        ---
        
******************************************************************************/

DelimFruct!(T, M) delimiters(T, M) (T[] src, const(M)[] set)
{
        DelimFruct!(T, M) elements;
        elements.set = set;
        elements.src = src;
        return elements;
}

/******************************************************************************

        Iterator to isolate text elements.

        Split the provided array wherever a pattern instance is found, 
        and return the resultant segments. Pattern are excluded from
        each of the segments, and an optional sub argument enables 
        replacement.
        
        ---
        foreach (segment; patterns ("one, two, three", ", "))
                 ...
        ---
        
******************************************************************************/

PatternFruct!(T) patterns(T) (const(T)[] src, const(T)[] pattern, const(T)[] sub=null)
{
        PatternFruct!(T) elements;
        elements.pattern = pattern;
        elements.sub = sub;
        elements.src = src;
        return elements;
}

/******************************************************************************

        Iterator to isolate optionally quoted text elements.

        As per elements(), but with the extension of being quote-aware;
        the set of delimiters is ignored inside a pair of quotes. Note
        that an unterminated quote will consume remaining content.
        
        ---
        foreach (quote; quotes ("one two 'three four' five", " "))
                 ...
        ---
        
******************************************************************************/

QuoteFruct!(T, M) quotes(T, M) (T[] src, const(M)[] set)
{
        QuoteFruct!(T, M) quotes;
        quotes.set = set;
        quotes.src = src;
        return quotes;
}

/*******************************************************************************

        Arranges text strings in order, using indices to specify where
        each particular argument should be positioned within the text. 
        This is handy for collating I18N components, or as a simplistic
        and lightweight formatter. Indices range from zero through nine. 
        
        ---
        // write ordered text to the console
        char[64] tmp;

        Cout (layout (tmp, "%1 is after %0", "zero", "one")).newline;
        ---

*******************************************************************************/

T[] layout(T) (T[] output, const(T)[][] layout ...)
{
        const(T)[] badarg  = cast(const(T)[])"{index out of range}";
        const(T)[] toosmall = cast(const(T)[])"{output buffer too small}";
        
        size_t  pos,
                args;
        bool    state;

        args = layout.length - 1;
        foreach (c; layout[0])
                {
                if (state)
                   {
                   state = false;
                   if (c >= '0' && c <= '9')
                      {
                      size_t index = c - '0';
                      if (index < args)
                         {
                         const(T)[] x = layout[index+1];

                         size_t limit = pos + x.length;
                         if (limit < output.length)
                            {
                            output [pos .. limit] = x;
                            pos = limit;
                            continue;
                            } 
                         else
                            return toosmall.dup;
                         }
                      else
                         return badarg.dup;
                      }
                   }
                else
                   if (c is '%')
                      {
                      state = true;
                      continue;
                      }

                if (pos < output.length)
                   {
                   output[pos] = c;
                   ++pos;
                   }
                else     
                   return toosmall.dup;
                }

        return output [0..pos];
}

/******************************************************************************

        Convert 'escaped' chars to normal ones: \t => ^t for example.
        Supports \" \' \\ \a \b \f \n \r \t \v
        
******************************************************************************/

T[] unescape(T) (const(T)[] src, T[] dst = null)
{
        size_t delta;
        auto s = src.ptr;
        auto len = src.length;

        // take a peek first to see if there's anything
        if ((delta = indexOf (s, '\\', len)) < len)
           {
           // make some room if not enough provided
           if (dst.length < src.length)
               dst.length = src.length;
           auto d = dst.ptr;

           // copy segments over, a chunk at a time
           do {
              d [0 .. delta] = s [0 .. delta];
              len -= delta;
              s += delta;
              d += delta;

              // bogus trailing '\'
              if (len < 2)
                 {
                 *d++ = '\\';
                 len = 0;
                 break;
                 }

              // translate \char
              T c = s[1];
              switch (c)
                     {
                      case '\\':
                           break;
                      case '\'':
                           c = '\'';
                           break;
                      case '"':
                           c = '"';
                           break;
                      case 'a':
                           c = '\a';
                           break;
                      case 'b':
                           c = '\b';
                           break;
                      case 'f':
                           c = '\f';
                           break;
                      case 'n':
                           c = '\n';
                           break;
                      case 'r':
                           c = '\r';
                           break;
                      case 't':
                           c = '\t';
                           break;
                      case 'v':
                           c = '\v';
                           break;
                      default:
                           *d++ = '\\';
                     }
              *d++ = c;  
              len -= 2;           
              s += 2;
              } while ((delta = indexOf (s, '\\', len)) < len);

           // copy tail too
           d [0 .. len] = s [0 .. len];
           return dst [0 .. (d + len) - dst.ptr];
           }
        // Bad dup?
        return src.dup;
}


/******************************************************************************

        jhash() -- hash a variable-length key into a 32-bit value

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

        See http://burtleburtle.net/bob/hash/evahash.html
        Use for hash table lookup, or anything where one collision in 2^32 
        is acceptable. Do NOT use for cryptographic purposes.

******************************************************************************/

size_t jhash (const(ubyte)* k, size_t len, size_t c = 0)
{
        size_t a = 0x9e3779b9,
             b = 0x9e3779b9,
             i = len;

        // handle most of the key 
        while (i >= 12) 
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
              k += 12; i -= 12;
              }

        // handle the last 11 bytes 
        c += len;
        switch (i)
               {
               case 11: c+=(cast(uint)k[10]<<24); goto case;
               case 10: c+=(cast(uint)k[9]<<16); goto case;
               case 9 : c+=(cast(uint)k[8]<<8); goto case;
               case 8 : b+=(cast(uint)k[7]<<24); goto case;
               case 7 : b+=(cast(uint)k[6]<<16); goto case;
               case 6 : b+=(cast(uint)k[5]<<8); goto case;
               case 5 : b+=(cast(uint)k[4]); goto case;
               case 4 : a+=(cast(uint)k[3]<<24); goto case;
               case 3 : a+=(cast(uint)k[2]<<16); goto case;
               case 2 : a+=(cast(uint)k[1]<<8); goto case;
               case 1 : a+=(cast(uint)k[0]); goto default;
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

/// ditto
size_t jhash (const(void)[] x, size_t c = 0)
{
        return jhash (cast(ubyte*) x.ptr, x.length, c);
}


/******************************************************************************
      
        Helper fruct for iterator lines(). A fruct is a low 
        impact mechanism for capturing context relating to an 
        opApply (conjunction of the names struct and foreach)
        
******************************************************************************/

private struct LineFruct(T)
{
        private T[] src;

        int opApply (scope int delegate (ref T[] line) dg)
        {
                int        ret;
                size_t     pos,
                           mark;
                T[] line;

                enum T nl = '\n';
                enum T cr = '\r';

                while ((pos = locate (src, nl, mark)) < src.length)
                      {
                      auto end = pos;
                      if (end && src[end-1] is cr)
                          --end;

                      line = src [mark .. end];
                      if ((ret = dg (line)) != 0)
                           return ret;
                      mark = pos + 1;
                      }

                line = src [mark .. $];
                if (mark <= src.length)
                    ret = dg (line);

                return ret;
        }
}

/******************************************************************************

        Helper fruct for iterator delims(). A fruct is a low 
        impact mechanism for capturing context relating to an 
        opApply (conjunction of the names struct and foreach)
        
******************************************************************************/

private struct DelimFruct(T, M)
{
        private T[] src;
        private const(M)[] set;

        int opApply (scope int delegate (ref T[] token) dg)
        {
                int     ret;
                size_t  pos,
                        mark;
                T[]     token;

                // optimize for single delimiter case
                if (set.length is 1)
                    while ((pos = locate (src, set[0], mark)) < src.length)
                          {
                          token = src [mark .. pos];
                          if ((ret = dg (token)) != 0)
                               return ret;
                          mark = pos + 1;
                          }
                else
                   if (set.length > 1)
                       foreach (i, elem; src)
                                if (contains (set, elem))
                                   {
                                   token = src [mark .. i];
                                   if ((ret = dg (token)) != 0)
                                        return ret;
                                   mark = i + 1;
                                   }

                token = src [mark .. $];
                if (mark <= src.length)
                    ret = dg (token);

                return ret;
        }
}

/******************************************************************************

        Helper fruct for iterator patterns(). A fruct is a low 
        impact mechanism for capturing context relating to an 
        opApply (conjunction of the names struct and foreach)
        
******************************************************************************/

private struct PatternFruct(T)
{
        private const(T)[] src,
                           sub,
                           pattern;

        int opApply (scope int delegate (ref const(T)[] token) dg)
        {
                int        ret;
                size_t     pos,
                           mark;
                const(T)[] token;

                while ((pos = index (src, pattern, mark)) < src.length)
                      {
                      token = src [mark .. pos];
                      if ((ret = dg(token)) != 0)
                           return ret;
                      if (sub.ptr && (ret = dg(sub)) != 0)
                          return ret;
                      mark = pos + pattern.length;
                      }

                token = src [mark .. $];
                if (mark <= src.length)
                    ret = dg (token);

                return ret;
        }
}

/******************************************************************************

        Helper fruct for iterator quotes(). A fruct is a low 
        impact mechanism for capturing context relating to an 
        opApply (conjunction of the names struct and foreach)
        
******************************************************************************/

private struct QuoteFruct(T, M)
{
        private T[]        src;
        private const(M)[] set;
        
        int opApply (scope int delegate (ref const(T)[] token) dg)
        {
                int     ret;
                size_t  mark;
                T[]     token;

                if (set.length)
                    for (size_t i=0; i < src.length; ++i)
                        {
                        T c = src[i];
                        if (c is '"' || c is '\'')
                            i = locate (src, c, i+1);
                        else
                           if (contains (set, c))
                              {
                              token = src [mark .. i];
                              if ((ret = dg (token)) != 0)
                                   return ret;
                              mark = i + 1;
                              }
                        }
                
                token = src [mark .. $];
                if (mark <= src.length)
                    ret = dg (token);

                return ret;
        }
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{    
        unittest
        {
        char[64] tmp;

        assert (isSpace (' ') && !isSpace ('d'));

        assert (indexOf ("abc".ptr, 'a', 3) is 0);
        assert (indexOf ("abc".ptr, 'b', 3) is 1);
        assert (indexOf ("abc".ptr, 'c', 3) is 2);
        assert (indexOf ("abc".ptr, 'd', 3) is 3);
        assert (indexOf ("abcabcabc".ptr, 'd', 9) is 9);

        assert (indexOf ("abc"d.ptr, cast(dchar)'c', 3) is 2);
        assert (indexOf ("abc"d.ptr, cast(dchar)'d', 3) is 3);
                                
        assert (indexOf ("abc"w.ptr, cast(wchar)'c', 3) is 2);
        assert (indexOf ("abc"w.ptr, cast(wchar)'d', 3) is 3);
        assert (indexOf ("abcdefghijklmnopqrstuvwxyz"w.ptr, cast(wchar)'x', 25) is 23);

        assert (mismatch ("abc".ptr, "abc".ptr, 3) is 3);
        assert (mismatch ("abc".ptr, "abd".ptr, 3) is 2);
        assert (mismatch ("abc".ptr, "acc".ptr, 3) is 1);
        assert (mismatch ("abc".ptr, "ccc".ptr, 3) is 0);

        assert (mismatch ("abc"w.ptr, "abc"w.ptr, 3) is 3);
        assert (mismatch ("abc"w.ptr, "acc"w.ptr, 3) is 1);
                                                
        assert (mismatch ("abc"d.ptr, "abc"d.ptr, 3) is 3);
        assert (mismatch ("abc"d.ptr, "acc"d.ptr, 3) is 1);

        assert (matching ("abc".ptr, "abc".ptr, 3));
        assert (matching ("abc".ptr, "abb".ptr, 3) is false);
        
        assert (contains ("abc", 'a'));
        assert (contains ("abc", 'b'));
        assert (contains ("abc", 'c'));
        assert (contains ("abc", 'd') is false);

        assert (containsPattern ("abc", "ab"));
        assert (containsPattern ("abc", "bc"));
        assert (containsPattern ("abc", "abc"));
        assert (containsPattern ("abc", "zabc") is false);
        assert (containsPattern ("abc", "abcd") is false);
        assert (containsPattern ("abc", "za") is false);
        assert (containsPattern ("abc", "cd") is false);

        assert (trim ("") == "");
        assert (trim (" abc  ") == "abc");
        assert (trim ("   ") == "");

        assert (strip ("", '%') == "");
        assert (strip ("%abc%%%", '%') == "abc");
        assert (strip ("#####", '#') == "");
        assert (stripl ("#####", '#') == "");
        assert (stripl (" ###", ' ') == "###");
        assert (stripl ("#####", 's') == "#####");
        assert (stripr ("#####", '#') == "");
        assert (stripr ("### ", ' ') == "###");
        assert (stripr ("#####", 's') == "#####");

        assert (replace ("abc".dup, 'b', ':') == "a:c");
        assert (substitute ("abc".dup, "bc", "x") == "ax");

        assert (locate ("abc", 'c', 1) is 2);

        assert (locate ("abc", 'c') is 2);
        assert (locate ("abc", 'a') is 0);
        assert (locate ("abc", 'd') is 3);
        assert (locate ("", 'c') is 0);

        assert (locatePrior ("abce", 'c') is 2);
        assert (locatePrior ("abce", 'a') is 0);
        assert (locatePrior ("abce", 'd') is 4);
        assert (locatePrior ("abce", 'c', 3) is 2);
        assert (locatePrior ("abce", 'c', 2) is 4);
        assert (locatePrior ("", 'c') is 0);

        auto x = delimit ("::b", ":");
        assert (x.length is 3 && x[0] == "" && x[1] == "" && x[2] == "b");
        x = delimit ("a:bc:d", ":");
        assert (x.length is 3 && x[0] == "a" && x[1] == "bc" && x[2] == "d");
        x = delimit ("abcd", ":");
        assert (x.length is 1 && x[0] == "abcd");
        x = delimit ("abcd:", ":");
        assert (x.length is 2 && x[0] == "abcd" && x[1] == "");
        x = delimit ("a;b$c#d:e@f", ";:$#@");
        assert (x.length is 6 && x[0]=="a" && x[1]=="b" && x[2]=="c" &&
                                 x[3]=="d" && x[4]=="e" && x[5]=="f");

        assert (locatePattern ("abcdefg", "") is 7);
        assert (locatePattern ("abcdefg", "g") is 6);
        assert (locatePattern ("abcdefg", "abcdefg") is 0);
        assert (locatePattern ("abcdefg", "abcdefgx") is 7);
        assert (locatePattern ("abcdefg", "cce") is 7);
        assert (locatePattern ("abcdefg", "cde") is 2);
        assert (locatePattern ("abcdefgcde", "cde", 3) is 7);

        assert (locatePatternPrior ("abcdefg", "") is 7);
        assert (locatePatternPrior ("abcdefg", "cce") is 7);
        assert (locatePatternPrior ("abcdefg", "cde") is 2);
        assert (locatePatternPrior ("abcdefgcde", "cde", 6) is 2);
        assert (locatePatternPrior ("abcdefgcde", "cde", 4) is 2);
        assert (locatePatternPrior ("abcdefg", "abcdefgx") is 7);

        x = splitLines ("a\nb\n");
        assert (x.length is 3 && x[0] == "a" && x[1] == "b" && x[2] == "");
        x = splitLines ("a\r\n");
        assert (x.length is 2 && x[0] == "a" && x[1] == "");

        x = splitLines ("a");
        assert (x.length is 1 && x[0] == "a");
        x = splitLines ("");
        assert (x.length is 1);

        const(char)[][] q;
        foreach (element; quotes ("1 'avcc   cc ' 3", " "))
                 q ~= element;
        assert (q.length is 3 && q[0] == "1" && q[1] == "'avcc   cc '" && q[2] == "3");

        assert (layout (tmp, "%1,%%%c %0", "abc", "efg") == "efg,%c abc");

        x = split ("one, two, three", ",");
        assert (x.length is 3 && x[0] == "one" && x[1] == " two" && x[2] == " three");
        x = split ("one, two, three", ", ");
        assert (x.length is 3 && x[0] == "one" && x[1] == "two" && x[2] == "three");
        x = split ("one, two, three", ",,");
        assert (x.length is 1 && x[0] == "one, two, three");
        x = split ("one,,", ",");
        assert (x.length is 3 && x[0] == "one" && x[1] == "" && x[2] == "");

        immutable(char)[] h, t;
        h =  head ("one:two:three", ":", t);
        assert (h == "one" && t == "two:three");
        h = head ("one:::two:three", ":::", t);
        assert (h == "one" && t == "two:three");
        h = head ("one:two:three", "*", t);
        assert (h == "one:two:three" && t is null);

        t =  tail ("one:two:three", ":", h);
        assert (h == "one:two" && t == "three");
        t = tail ("one:::two:three", ":::", h);
        assert (h == "one" && t == "two:three");
        t = tail ("one:two:three", "*", h);
        assert (t == "one:two:three" && h is null);

        assert (chopl("hello world", "hello ") == "world");
        assert (chopl("hello", "hello") == "");
        assert (chopl("hello world", " ") == "hello world");
        assert (chopl("hello world", "") == "hello world");

        assert (chopr("hello world", " world") == "hello");
        assert (chopr("hello", "hello") == "");
        assert (chopr("hello world", " ") == "hello world");
        assert (chopr("hello world", "") == "hello world");

        const(char)[][] foo = ["one", "two", "three"];
        auto j = join (foo);
        assert (j == "onetwothree");
        j = join (foo, ", ");
        assert (j == "one, two, three");
        j = join (foo, " ", tmp);
        assert (j == "one two three");
        assert (j.ptr is tmp.ptr);

        assert (repeat ("abc", 0) == "");
        assert (repeat ("abc", 1) == "abc");
        assert (repeat ("abc", 2) == "abcabc");
        assert (repeat ("abc", 4) == "abcabcabcabc");
        assert (repeat ("", 4) == "");
        char[10] rep;
        assert (repeat ("abc", 0, rep) == "");
        assert (repeat ("abc", 1, rep) == "abc");
        assert (repeat ("abc", 2, rep) == "abcabc");
        assert (repeat ("", 4, rep) == "");

        assert (unescape ("abc") == "abc");
        assert (unescape ("abc\\") == "abc\\");
        assert (unescape ("abc\\t") == "abc\t");
        assert (unescape ("abc\\tc") == "abc\tc");
        assert (unescape ("\\t") == "\t");
        assert (unescape ("\\tx") == "\tx");
        assert (unescape ("\\v\\vx") == "\v\vx");
        assert (unescape ("abc\\t\\a\\bc") == "abc\t\a\bc");
        }
}



debug (Util)
{
        auto x = import("Util.d");
        
        void main()
        {
                mismatch ("".ptr, S(x).ptr, 0);
                indexOf ("".ptr, '@', 0);
                char[] s;
                split (s, " ");
                //indexOf (s.ptr, '@', 0);

        }
}
