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
        
        text = "happy";
        assert (text[0 .. locate (text, '!')] == "happy");
        ---

        For trivial lookup cases, use the contains() function instead:
        ---
        if (contains ("fubar", '!'))
            ...
        ---

        Note that where some functions expect a uint as an argument, the
        D template-matching algorithm will fail where an int is provided
        instead. This is the typically the cause of "template not found"
        errors. Also note that name overloading is not supported by IFTI
        at this time, so is not applicable here.

        Lastly: it is *highly* recommended to apply the D "import alias"
        mechanism to this module, in order to limit namespace pollution:
        ---
        import Util = tango.text.Util;

        auto s = Util.trim ("  foo ");
        ---
                
        Function templates:
        ---
        trim (source)
        strip (source, match)
        split (source, delimeter)
        replace (source, match, replacement)
        contains (source, match)
        locate (source, match, start)
        locatePrior (source, match, start)
        locatePattern (source, match, start);
        locatePatternPrior (source, match, start);
        indexOf (s*, match, length)
        mismatch (s1*, s2*, length)
        matching (s1*, s2*, length)
        isSpace (match)
        ---

*******************************************************************************/

module tango.text.Util;

/******************************************************************************

        Trim the provided string by stripping whitespace from both
        ends. Returns a slice of the original content

******************************************************************************/

T[] trim(T) (T[] source)
{
        T*   head = source.ptr,
             tail = head + source.length;

        while (head < tail && isSpace(*head))
               ++head;

        while (tail > head && isSpace(*(tail-1)))
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Trim the provided string by stripping the provided chr from
        both ends. Returns a slice of the original content

******************************************************************************/

T[] strip(T) (T[] source, T chr)
{
        T*   head = source.ptr,
             tail = head + source.length;

        while (head < tail && *head is chr)
               ++head;

        while (tail > head && *(tail-1) is chr)
               --tail;

        return head [0 .. tail - head];
}

/******************************************************************************

        Replace all instances of one char with another (in place)

******************************************************************************/

T[] replace(T) (T[] source, T match, T replacement)
{
        foreach (inout c; source)
                 if (c is match)
                     c = replacement;
        return source;
}

/******************************************************************************

        Returns whether or not the provided array contains an instance
        of the given match
        
******************************************************************************/

bool contains(T) (T[] source, T match)
{
        return indexOf (source.ptr, match, source.length) != source.length;
}

/******************************************************************************

        Return the index of the next instance of 'match' starting at
        position 'start', or source.length where there is no match.

        Parameter 'start' defaults to 0

******************************************************************************/

uint locate(T) (T[] source, T match, uint start=0)
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

uint locatePrior(T) (T[] source, T match, uint start=uint.max)
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

uint locatePattern(T) (T[] source, T[] match, uint start=0)
{
        uint    idx;
        T*      p = source.ptr + start;
        uint    extent = source.length - start - match.length + 1;

        if (extent >= source.length || match.length is 0)
            return source.length;

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

        return source.length;
}
   
/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or source.length where there is no match.

        Parameter 'start' defaults to source.length

******************************************************************************/

uint locatePatternPrior(T) (T[] source, T[] match, uint start=uint.max)
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
                     if (matching (source.ptr+start, match.ptr, match.length))
                         return start;
                  }

        return len;
}

/******************************************************************************

        Split the provided array wherever a delim instance is found
        and return the resultant segments. The delimeter is excluded
        from each of the segments

******************************************************************************/

T[][] split(T) (T[] src, T delim)
{
        uint    pos,
                mark;
        T[][]   result;

        while ((pos = locate (src, delim, pos)) != src.length)
              {
              result ~= src [mark .. pos];
              mark = pos += 1;
              }

        if (mark < src.length)
            result ~= src [mark .. $];

        return result;
}

/******************************************************************************

        Is the argument a whitespace character?

******************************************************************************/

bool isSpace(T) (T c)
{
        return (c is ' ' | c is '\t' | c is '\r' | c is '\n');
}

/******************************************************************************

        Return whether or not the two arrays have matching content
        
******************************************************************************/

bool matching(T) (T* s1, T* s2, uint length)
{
        return mismatch(s1, s2, length) is length;
}

/******************************************************************************

        Returns the index of the first match in str, failing once
        length is reached. Note that we return 'length' for failure
        and a 0-based index on success

******************************************************************************/

uint indexOf(T) (T* str, T match, uint length)
{
        version (D_InlineAsm_X86)
        {       
                static if (T.sizeof == 1)
                {
                        asm {
                            mov   EDI, str;
                            mov   ECX, length;
                            movzx EAX, match;
                            mov   ESI, ECX;
                            and   ESI, ESI;            
                            jz    end;        

                            cld;
                            repnz;
                            scasb;
                            jnz   end;
                            sub   ESI, ECX;
                            dec   ESI;
                        end:;
                            mov   EAX, ESI;
                            }
                }
                else static if (T.sizeof == 2)
                {
                        asm {
                            mov   EDI, str;
                            mov   ECX, length;
                            movzx EAX, match;
                            mov   ESI, ECX;
                            and   ESI, ESI;            
                            jz    end;        

                            cld;
                            repnz;
                            scasw;
                            jnz   end;
                            sub   ESI, ECX;
                            dec   ESI;
                        end:;
                            mov   EAX, ESI;
                            }
                }
                else static if (T.sizeof == 4)
                {
                        asm {
                            mov   EDI, str;
                            mov   ECX, length;
                            mov   EAX, match;
                            mov   ESI, ECX;
                            and   ESI, ESI;            
                            jz    end;        

                            cld;
                            repnz;
                            scasd;
                            jnz   end;
                            sub   ESI, ECX;
                            dec   ESI;
                        end:;
                            mov   EAX, ESI;
                            }
                }
                else
                {
                        auto len = length;
                        for (auto p=str-1; len--;)
                             if (*++p is match)
                                 return p - str;
                        return length;
                }
        }
        else
        {
                auto len = length;
                for (auto p=str-1; len--;)
                     if (*++p is match)
                         return p - str;
                return length;
        }
}

/******************************************************************************

        Returns the index of a mismatch between s1 & s2, failing when
        length is reached. Note that we return 'length' upon failure
        (array content matches) and a 0-based index upon success.

        Use this as a faster opEquals (the assembler version). Also
        provides the basis for a much faster opCmp, since the index
        of the first mismatched character can be used to determine
        the (greater or less than zero) return value

******************************************************************************/

uint mismatch(T) (T* s1, T* s2, uint length)
{
        version (D_InlineAsm_X86)
        {
                static if (T.sizeof == 1)
                {
                        asm {
                            mov   EDI, s1;
                            mov   ESI, s2;
                            mov   ECX, length;
                            mov   EAX, ECX;
                            and   EAX, EAX;
                            jz    end;

                            cld;
                            repz;
                            cmpsb;
                            jz    end;
                            sub   EAX, ECX;
                            dec   EAX;
                        end:;
                            }
                }
                else static if (T.sizeof == 2)
                {
                        asm {
                            mov   EDI, s1;
                            mov   ESI, s2;
                            mov   ECX, length;
                            mov   EAX, ECX;
                            and   EAX, EAX;
                            jz    end;

                            cld;
                            repz;
                            cmpsw;
                            jz    end;
                            sub   EAX, ECX;
                            dec   EAX;
                        end:;
                            }
                }
                else static if (T.sizeof == 4)
                {
                        asm {
                            mov   EDI, s1;
                            mov   ESI, s2;
                            mov   ECX, length;
                            mov   EAX, ECX;
                            and   EAX, EAX;
                            jz    end;

                            cld;
                            repz;
                            cmpsd;
                            jz    end;
                            sub   EAX, ECX;
                            dec   EAX;
                        end:;
                            }
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

******************************************************************************/

debug (UnitTest)
{
        void main() {}
        
        unittest       
        {
        assert (isSpace (' ') && !isSpace ('d'));

        assert (indexOf ("abc".ptr, 'a', 3u) is 0);
        assert (indexOf ("abc".ptr, 'b', 3u) is 1);
        assert (indexOf ("abc".ptr, 'c', 3u) is 2);
        assert (indexOf ("abc".ptr, 'd', 3u) is 3);

        assert (mismatch ("abc".ptr, "abc".ptr, 3u) is 3);
        assert (mismatch ("abc".ptr, "abd".ptr, 3u) is 2);
        assert (mismatch ("abc".ptr, "acc".ptr, 3u) is 1);
        assert (mismatch ("abc".ptr, "ccc".ptr, 3u) is 0);

        assert (matching ("abc".ptr, "abc".ptr, 3u));
        assert (matching ("abc".ptr, "abb".ptr, 3u) is false);
        
        assert (contains ("abc", 'a'));
        assert (contains ("abc", 'b'));
        assert (contains ("abc", 'c'));
        assert (contains ("abc", 'd') is false);

        assert (trim ("") == "");
        assert (trim (" abc  ") == "abc");
        assert (trim ("   ") == "");

        assert (strip ("", '%') == "");
        assert (strip ("%abc%%%", '%') == "abc");
        assert (strip ("#####", '#') == "");

        assert (replace ("abc".dup, 'b', ':') == "a:c");

        assert (locate ("abc", 'c') is 2);
        assert (locate ("abc", 'a') is 0);
        assert (locate ("abc", 'd') is 3);
        assert (locate ("", 'c') is 0);

        assert (locatePrior ("abce", 'c') is 2);
        assert (locatePrior ("abce", 'a') is 0);
        assert (locatePrior ("abce", 'd') is 4);
        assert (locatePrior ("abce", 'c', 3u) is 2);
        assert (locatePrior ("abce", 'c', 2u) is 4);
        assert (locatePrior ("", 'c') is 0);

        auto x = split ("a:bc:d", ':');
        assert (x.length is 3 && x[0] == "a" && x[1] == "bc" && x[2] == "d");

        x = split ("abcd", ':');
        assert (x.length is 1 && x[0] == "abcd");

        x = split ("abcd:", ':');
        assert (x.length is 1 && x[0] == "abcd");

        assert (locatePattern ("abcdefg", "") is 7);
        assert (locatePattern ("abcdefg", "abcdefg") is 0);
        assert (locatePattern ("abcdefg", "abcdefgx") is 7);
        assert (locatePattern ("abcdefg", "cce") is 7);
        assert (locatePattern ("abcdefg", "cde") is 2);
        assert (locatePattern ("abcdefgcde", "cde", 3u) is 7);

        assert (locatePatternPrior ("abcdefg", "") is 7);
        assert (locatePatternPrior ("abcdefg", "cce") is 7);
        assert (locatePatternPrior ("abcdefg", "cde") is 2);
        assert (locatePatternPrior ("abcdefgcde", "cde", 6u) is 2);
        assert (locatePatternPrior ("abcdefgcde", "cde", 4u) is 2);
        assert (locatePatternPrior ("abcdefg", "abcdefgx") is 7);
        assert (locatePatternPrior ("abcdefg", "abcdefg") is 0);
        }
}
