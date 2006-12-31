/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004

        author:         Kris


        Placeholder for a variety of wee functions. These functions are all
        templated with the intent of being used for arrays of char, wchar,
        and dchar. However, most will operate just fine with other types
        also.
        
*******************************************************************************/

module tango.text.Goodies;

/******************************************************************************

        Trim the provided string by stripping whitespace from
        both ends. Returns a slice of the original content.

******************************************************************************/

template trim (T)
{
        T[] trim (T[] source)
        {
                int  front,
                     back = source.length;

                if (back)
                   {
                   while (front < back && isSpace(source[front]))
                          ++front;

                   while (back > front && isSpace(source[back-1]))
                          --back;
                   }
                return source [front .. back];
        }
}

/******************************************************************************

        Replace all instances of one char with another (in place)

******************************************************************************/

template replace (T)
{
        T[] replace (T[] source, T match, T replacement)
        {
                foreach (inout c; source)
                         if (c is match)
                             c = replacement;
                return source;
        }
}

/******************************************************************************

        Return the index of the next instance of 'match' starting
        at position 'start', or zero where there is no match. Note
        that the returned index is 1-based, not 0-based.

        Parameter 'start' defaults to 0

******************************************************************************/

template find (T)
{
        uint find (T[] source, T match, uint start=0)
        {
                assert (start < source.length);
                
                return locate (&source[start], match, source.length - start);
        }
}

/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or zero where there is no match. Note
        that the returned index is 1-based, not 0-based

        Parameter 'start' defaults to source.length

******************************************************************************/

template findPrior (T)
{
        uint findPrior (T[] source, T match, uint start=uint.max)
        {
                if (start is uint.max)
                    start = source.length;

                assert (start <= source.length);

                while (start > 0)
                       if (source[--start] is match)
                           return start + 1;
                return 0;
        }
}

/******************************************************************************

        Return the index of the next instance of 'match' starting
        at position 'start', or zero where there is no match. Note
        that the returned index is 1-based, not 0-based.

        Parameter 'start' defaults to 0

******************************************************************************/

template search (T)
{
        uint search (T[] source, T[] match, uint start=0)
        {
                uint    idx;
                T*      p = source.ptr + start;
                uint    extent = source.length - start - match.length + 1;

                if (extent >= source.length || match.length is 0)
                    return 0;
                
                while (extent)
                       if ((idx = locate (p, match[0], extent)) is 0)
                            break;
                       else
                          {
                          p += idx;
                          extent -= idx;
                          if (! mismatch (p-1, match.ptr, match.length))
                                return p - source.ptr;
                          }
                return 0;
        }
}
   
/******************************************************************************

        Return the index of the prior instance of 'match' starting
        just before 'start', or zero where there is no match. Note
        that the returned index is 1-based, not 0-based

        Parameter 'start' defaults to source.length

******************************************************************************/

template searchPrior (T)
{
        uint searchPrior (T[] source, T[] match, uint start=uint.max)
        {
                if (start is uint.max)
                    start = source.length;

                assert (start <= source.length);

                if (match.length is 0 || match.length > source.length)
                    return 0;

                while (start)
                      {
                      auto found = findPrior (source, match[0], start);
                      if (found)
                          if (mismatch (source.ptr+found-1, match.ptr, match.length))
                              start = found-1;
                          else
                             return found;
                      else
                         break;
                      }

                return 0;
        }
}

/******************************************************************************

        Split the provided array wherever a delim instance is found
        and return the resultant segments. The delimeter is excluded
        from each of the segments

******************************************************************************/

template split (T)
{
        T[][] split (T[] src, T delim)
        {
                uint    pos,
                        mark;
                T[][]   result;

                while ((pos = find (src, delim, pos)) > 0)
                      {
                      result ~= src [mark .. pos-1];
                      mark = pos;
                      }

                if (mark < src.length)
                    result ~= src [mark .. $];

                return result;
        }
}

/******************************************************************************

        Is the argument a whitespace character?

******************************************************************************/

template isSpace (T)
{
        bool isSpace (T c)
        {
                return (c is ' ' | c is '\t' | c is '\r' | c is '\n');
        }
}

/******************************************************************************

        Returns the index of the first match in str, failing once
        length is reached. Note that we return 0 for failure and
        a 1-based index on success (not a 0-based index)

******************************************************************************/

template locate (T)
{
        uint locate (T* str, T match, uint length)
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

                                    cld;
                                    repnz;
                                    scasb;
                                    jz    ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok:
                                    mov   EAX, ESI;
                                    sub   EAX, ECX;
                                end:;
                                    }
                        }
                        else static if (T.sizeof == 2)
                        {
                                asm {
                                    mov   EDI, str;
                                    mov   ECX, length;
                                    movzx EAX, match;
                                    mov   ESI, ECX;

                                    cld;
                                    repnz;
                                    scasw;
                                    jz    ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok:
                                    mov   EAX, ESI;
                                    sub   EAX, ECX;
                                end:;
                                    }
                        }
                        else static if (T.sizeof == 4)
                        {
                                asm {
                                    mov   EDI, str;
                                    mov   ECX, length;
                                    mov   EAX, match;
                                    mov   ESI, ECX;

                                    cld;
                                    repnz;
                                    scasd;
                                    jz    ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok:
                                    mov   EAX, ESI;
                                    sub   EAX, ECX;
                                end:;
                                    }
                        }
                        else
                        {
                                for (auto p=str; length--;)
                                     if (*p++ == match)
                                         return p - str;
                                return 0;
                        }
                }
                else
                {
                        for (auto p=str; length--;)
                             if (*p++ == match)
                                 return p - str;
                        return 0;
                }
        }
}

/******************************************************************************

        Returns the index of a mismatch between s1 & s2, failing
        when length is reached. Note that we return 0 for failure
        (no mismatch found) and a 1-based index on success; not a
        0-based index.

        Use this as a faster opEquals (the assembler version).
        Also provides the basis for a much faster opCmp, since
        the index of the first mismatched character can be used
        to determine the (greater or less than zero) return value

******************************************************************************/

template mismatch (T)
{
        uint mismatch (T* s1, T* s2, uint length)
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

                                    cld;
                                    repz;
                                    cmpsb;
                                    jnz   ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok: sub   EAX, ECX;
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

                                    cld;
                                    repz;
                                    cmpsw;
                                    jnz   ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok: sub   EAX, ECX;
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

                                    cld;
                                    repz;
                                    cmpsd;
                                    jnz   ok;
                                    xor   EAX, EAX;
                                    jmp   end;
                                ok: sub   EAX, ECX;
                                end:;
                                    }
                        }
                        else
                        {
                                for (auto p=s1; length--;)
                                     if (*p++ != *s2++)
                                         return p - s1;
                                return 0;
                        }
                }
                else
                {
                        for (auto p=s1; length--;)
                             if (*p++ != *s2++)
                                 return p - s1;
                        return 0;
                }
        }
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
unittest       
{
        assert (isSpace (' ') && !isSpace ('d'));

        assert (locate ("abc".ptr, 'a', 3u) is 1);
        assert (locate ("abc".ptr, 'b', 3u) is 2);
        assert (locate ("abc".ptr, 'c', 3u) is 3);
        assert (locate ("abc".ptr, 'd', 3u) is 0);

        assert (mismatch ("abc".ptr, "abc".ptr, 3u) is 0);
        assert (mismatch ("abc".ptr, "abd".ptr, 3u) is 3);
        assert (mismatch ("abc".ptr, "acc".ptr, 3u) is 2);
        assert (mismatch ("abc".ptr, "ccc".ptr, 3u) is 1);

        assert (trim (" abc  ") == "abc");
        assert (trim ("   ") == "");

        assert (replace ("abc".dup, 'b', ':') == "a:c");

        assert (find ("abc", 'c') is 3);
        assert (find ("abc", 'a') is 1);
        assert (find ("abc", 'd') is 0);
        
        assert (findPrior ("abc", 'c') is 3);
        assert (findPrior ("abc", 'a') is 1);
        assert (findPrior ("abc", 'd') is 0);

        auto x = split ("a:b", ':');
        assert (x.length is 2 && x[0] == "a" && x[1] == "b");

        assert (search ("abcdefg", "") is 0);
        assert (search ("abcdefg", "abcdefg") is 1);
        assert (search ("abcdefg", "abcdefgx") is 0);
        assert (search ("abcdefg", "cce") is 0);
        assert (search ("abcdefg", "cde") is 3);
        assert (search ("abcdefgcde", "cde", 3u) is 8);

        assert (searchPrior ("abcdefg", "") is 0);
        assert (searchPrior ("abcdefg", "cce") is 0);
        assert (searchPrior ("abcdefg", "cde") is 3);
        assert (searchPrior ("abcdefgcde", "cde", 6u) is 3);
        assert (searchPrior ("abcdefgcde", "cde", 4u) is 3);
        assert (searchPrior ("abcdefg", "abcdefg") is 1);
        assert (searchPrior ("abcdefg", "abcdefgx") is 0);
}
}
