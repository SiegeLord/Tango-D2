/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius and Kris Bell.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius and Kris Bell
 */

module tango.text.xml.XmlIterator;

private import Util = tango.text.Util;

package struct XmlIterator(Ch)
{
        package Ch*     end;
        package size_t  len;
        package Ch[]    text;
        package Ch*     point;

        final bool good()
        {
                return point < end;
        }
        
        final Ch[] opSlice(size_t x, size_t y)
        in {
                if ((point+y) >= end || y < x)
                     assert(false);                  
           }
        body
        {               
                return point[x .. y];
        }
        
        final void seek(size_t position)
        in {
                if (position >= len) 
                    assert(false);
           }
        body
        {
                point = text.ptr + position;
        }

        final void reset(Ch[] newText)
        {
                this.text = newText;
                this.len = newText.length;
                this.point = text.ptr;
                this.end = point + len;
        }

        final bool forwardLocate(Ch ch)
        {
            version(D_InlineAsm_X86)
            {   
                static if(Ch.sizeof == 1)
                {   
                    char* pitr_ = point;
                    void* e_ = end;
                    bool res;
                    asm
                    {
                         mov EDI, pitr_;
                         mov ECX, e_;
                         sub   ECX, EDI;
                         jng    fail;
                         movzx   EAX, ch;
                         
                         cld;
                         repnz;
                         scasb;
                         jnz   fail;
                         
                         dec EDI;
                         mov   pitr_, EDI;
                         mov   AL, 1;
                         jmp   end_;
                     fail:;
                         xor   AL, AL;
                     end_:;
                         mov res, AL;
                    }
                    point = pitr_;
                    return res;
                }
                else
                {
                    auto tmp = end - point;
                    auto l = Util.indexOf!(Ch)(point, ch, tmp);
                    if (l < tmp) 
                       {
                       point += l;
                       return true;
                       }
                    return false;
                }
            }
            else
            {
                auto tmp = end - point;
                    auto l = Util.indexOf!(Ch)(point, ch, tmp);
                    if (l < tmp) 
                       {
                       point += l;
                       return true;
                       }
                    return false;
            }
        }
        
        final Ch* forwardLocate(Ch* p, Ch ch)
        {
            version(D_InlineAsm_X86)
            {   
                static if(Ch.sizeof == 1)
                {   
                    auto e_ = end;
                    asm
                    {
                         mov    EDI, p;
                         mov    ECX, e_;
                         sub    ECX, EDI;
                         jng    fail;
                         movzx  EAX, ch;
                         
                         cld;
                         repnz;
                         scasb;
                         jnz    fail;
                         
                         dec    EDI;
                         jmp    end_;
                     fail:;
                         xor    EDI, EDI;
                     end_:;
                         mov    e_, EDI;
                    }
                    if (e_)
                        return e_;
                    throw new Exception ("malformed XML");
                }
                else
                {
                    auto tmp = end - point;
                    auto l = Util.indexOf!(Ch)(point, ch, tmp);
                    if (l < tmp) 
                        return p + l;
                    throw new Exception ("malformed XML");
                }
            }
            else
            {
                    auto tmp = end - p;
                    auto l = Util.indexOf!(Ch)(p, ch, tmp);
                    if (l < tmp) 
                        return p += l;
                    throw new Exception ("malformed XML");
            }
        }
        
        final Ch* eatElemName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || name[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final Ch* eatAttrName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || attributeName[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final Ch* eatAttrName(Ch* p)
        {      
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || attributeName[c])
                          ++p;
                      else
                         break;
                      }
                return p;
        }
        
        final bool eatSpace()
        {
                auto p = point;
                auto e = end;
                while (p < e)
                      {                
                      if (*p <= 32)                                          
                          ++p;
                      else
                         {
                         point = p;
                         return true;
                         }                                  
                      }
               point = p;
               return false;
        }

        final Ch* eatSpace(Ch* p)
        {
                auto e = end;
                while (p < e)
                      {                
                      if (*p <= 32)                                          
                          ++p;
                      else
                         break;
                      }
               return p;
        }

        static const ubyte name[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0   // 3
        ];

        static const ubyte attributeName[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0   // 3
        ];
}