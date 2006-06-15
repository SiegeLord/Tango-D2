/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.text.Text;

/******************************************************************************

        Placeholder for a variety of wee functions. Some of these are
        handy for Java programmers, but the primary reason for their
        existance is that they don't allocate memory ~ processing is 
        performed in-place.

******************************************************************************/

struct TextT(T)
{
        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Template type must be char, wchar, or dchar");


        /**********************************************************************

                Replace all instances of one char with another (in place)

        **********************************************************************/

        final static T[] replace (T[] source, T match, T replacement)
        {
                T*  p;
                T*  scan = source;
                int length = source.length;

                while ((p = locate (scan, match, length)) != null)
                      {
                      *p = replacement;
                      length -= (p - scan);
                      scan = p;
                      }
                return source;
        }

        /**********************************************************************

                Return the index of the next instance of 'match', starting
                at position 'start'
                
        **********************************************************************/

        final static int indexOf (T[] source, T match, int start=0)
        {
                if (start < source.length)
                   {
                   T *p = locate (&source[start], match, source.length - start);
                   if (p)
                       return p - source.ptr;
                   }
                return -1;
        }

        /**********************************************************************

                Return the index of the next instance of 'match', starting
                at position 'start'
                
        **********************************************************************/

        final static int indexOf (T[] source, T[] match, int start=0)
        {
                T*      p;
                int     length = match.length;
                int     extent = source.length - length + 1;
                
                if (length && extent >= 0)
                    for (; start < extent; ++start)
                           if ((p = locate (source.ptr+start, match[0], extent-start)) != null)
                                if (equal (p, match.ptr, length))
                                    return p - source.ptr;
                               else
                                  start = p - source.ptr;

                return -1;
        }

        /**********************************************************************

                Return the index of the prior instance of 'match', starting
                at position 'start'
                
        **********************************************************************/

        final static int rIndexOf (T[] source, T match, int start=int.max)
        {
                if (start is int.max)
                    start = source.length;

                for (int i=start; i-- > 0;)
                     if (source[i] is match)
                         return i;

                return -1;
        }

        /**********************************************************************

                Return the index of the prior instance of 'match', starting
                at position 'start'
                
        **********************************************************************/

        final static int rIndexOf (T[] source, T[] match, int start=int.max)
        {
                int length = match.length;

                if (start is int.max)
                    start = source.length;

                start -= length;
                while (start >= 0)
                      {
                      int found = rIndexOf (source, match[0], start);
                      if (found < 0)
                          break;
                      else
                         if (equal (match, source.ptr + found, length))
                             return found;
                         else
                            start = found;
                      }

                return -1;
        }

        /**********************************************************************

                Is the argument a whitespace character?

        **********************************************************************/

        final static bool isSpace (T c)
        {
                return cast(bool) (c is ' ' || c is '\t' || c is '\r' || c is '\n');
        }

        /**********************************************************************

                Trim the provided string by stripping whitespace from 
                both ends. Returns a slice of the original content.

        **********************************************************************/

        final static T[] trim (T[] source)
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

        /**********************************************************************

                
        **********************************************************************/

        final static T[][] split (T[] src, T[] delim)
        {
                int     pos,
                        mark;
                T[][]   ret;

                assert (delim.length);
                while ((pos = indexOf (src, delim, pos)) >= 0)
                      { 
                      ret ~= src [mark..pos];
                      pos += delim.length;
                      mark = pos;
                      }

                if (mark < src.length)
                    ret ~= src [mark..src.length];
                return ret;                                      
        }

        /**********************************************************************

        **********************************************************************/

        version (X86)
        {
                static if (is(T == char))
                {
                        static char* locate (char* s, char match, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ECX, length; 
                                movzx EAX, match;

                                cld;
                                repnz;
                                scasb;
                                jz    ok;
                                xor   EAX, EAX;
                                jmp   fail;
                        ok:
                                lea   EAX, [EDI-1];
                        fail:;
                                }
                        }

                        static bool equal (char* s, char* d, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ESI, d;
                                mov   ECX, length; 
                                xor   EAX, EAX;

                                cld;
                                repz;
                                cmpsb;
                                jnz   fail;
                                inc   EAX;
                        fail:;
                                }
                        }
                }        

                static if (is(T == wchar))
                {
                        static wchar* locate (wchar* s, wchar match, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ECX, length; 
                                movzx EAX, match;

                                cld;
                                repnz;
                                scasw;
                                jz    ok;
                                xor   EAX, EAX;
                                jmp   fail;
                        ok:
                                lea   EAX, [EDI-2];
                        fail:;
                                }
                        }

                        static bool equal (wchar* s, wchar* d, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ESI, d;
                                mov   ECX, length; 
                                xor   EAX, EAX;

                                cld;
                                repz;
                                cmpsw;
                                jnz   fail;
                                inc   EAX;
                        fail:;
                                }
                        }
                }        

                static if (is(T == dchar))
                {
                        static dchar* locate (dchar* s, dchar match, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ECX, length; 
                                mov   EAX, match;

                                cld;
                                repnz;
                                scasd;
                                jz    ok;
                                xor   EAX, EAX;
                                jmp   fail;
                        ok:
                                lea   EAX, [EDI-4];
                        fail:;
                                }
                        }

                        static bool equal (dchar* s, dchar* d, int length)
                        {
                                asm 
                                {
                                mov   EDI, s;
                                mov   ESI, d;
                                mov   ECX, length; 
                                xor   EAX, EAX;

                                cld;
                                repz;
                                cmpsd;
                                jnz   fail;
                                inc   EAX;
                        fail:;
                                }
                        }
                }    
        }
        else
        {
                static T* locate (T* s, T match, int len)
                {
                        while (len--)
                               if (*s++ == match)
                                   return s-1;
                        return null;
                }
                
                static bool equal (T* s, T* d, int len)
                {
                        while (len--)
                               if (*s++ != *d++)
                                   return false;
                        return true;
                }
                
        }    
}


/******************************************************************************

        Placeholder for a variety of wee functions. Some of these are
        handy for Java programmers, but the primary reason for their
        existance is that they don't allocate memory ~ processing is 
        performed in-place.

******************************************************************************/

alias TextT!(char) Text;


debug (UnitTest)
{
private import tango.io.Console;

unittest
{
        try 
        {
        char[] test = "123456789";
        assert (Text.locate (test, 'a', test.length) == null);
        assert (Text.locate (test, '3', test.length) == &test[2]);
        assert (Text.locate (test, '1', test.length) == &test[0]);

        assert (Text.equal (test, test, test.length));
        assert (!Text.equal (test, "qwe", 3));
        } catch (Object o)
                 Cout (o.toString() ~ "\n");
}
}
