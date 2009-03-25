/*******************************************************************************

        Copyright: Copyright (C) 2008 Kris Bell, all rights reserved

        License:   BSD style: $(LICENSE)

        version:   July 2008: Initial release

        Authors:   Kris

*******************************************************************************/

module tango.text.json.JsonEscape;

private import tango.text.json.JsonParser;

private import Util = tango.text.Util;

private import Utf = tango.text.convert.Utf;

/******************************************************************************

        Convert 'escaped' chars to normal ones. For example: \\ => \

        The provided output buffer should be at least as long as the 
        input string, or it will be allocated from the heap instead.

        Returns a slice of dst where the content required conversion, 
        or the provided src otherwise
        
******************************************************************************/

T[] unescape(T) (T[] src, T[] dst = null)
{
        int delta;
        auto s = src.ptr;
        auto len = src.length;
        enum:T {slash = '\\'};

        // take a peek first to see if there's anything
        if ((delta = Util.indexOf (s, slash, len)) < len)
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

              // translate \c
              switch (s[1])
                     {
                      case '\\':
                           *d++ = '\\';
                           break;

                      case '/':
                           *d++ = '/';
                           break;

                      case '"':
                           *d++ = '"';
                           break;

                      case 'b':
                           *d++ = '\b';
                           break;

                      case 'f':
                           *d++ = '\f';
                           break;

                      case 'n':
                           *d++ = '\n';
                           break;

                      case 'r':
                           *d++ = '\r';
                           break;

                      case 't':
                           *d++ = '\t';
                           break;

                      case 'u':
                           if (len < 6)
                               goto default;
                           else
                              {
                              dchar v = 0;
                              T[6]  t = void;

                              for (auto i=2; i < 6; ++i)
                                  {
                                  auto c = s[i];
                                  if (c >= '0' && c <= '9')
                                     {}
                                  else
                                     if (c >= 'a' && c <= 'f')
                                         c -= 39;
                                     else
                                        if (c >= 'A' && c <= 'F')
                                            c -= 7;
                                        else
                                           goto default;
                                  v = (v << 4) + c - '0';
                                  }
                              
                              auto c = Utf.fromString32 ((&v)[0..1], t);
                              d [0 .. c.length] = c;
                              d += c.length;
                              len -= 4;
                              s += 4;
                              }
                           break;

                      default:
                           throw new Exception ("invalid escape");
                     }

              s += 2;
              len -= 2;           
              } while ((delta = Util.indexOf (s, slash, len)) < len);

           // copy tail too
           d [0 .. len] = s [0 .. len];
           return dst [0 .. (d + len) - dst.ptr];
           }
        return src;
}


/******************************************************************************

        Convert 'escaped' chars to normal ones. For example: \\ => \

        This variant does not require an interim workspace, and instead
        emits directly via the provided delegate
              
******************************************************************************/

void unescape(T) (T[] src, void delegate(T[]) emit)
{
        int delta;
        auto s = src.ptr;
        auto len = src.length;
        enum:T {slash = '\\'};

        // take a peek first to see if there's anything
        if ((delta = Util.indexOf (s, slash, len)) < len)
           {
           // copy segments over, a chunk at a time
           do {
              emit (s[0 .. delta]);
              len -= delta;
              s += delta;

              // bogus trailing '\'
              if (len < 2)
                 {
                 emit ("\\");
                 len = 0;
                 break;
                 }

              // translate \c
              switch (s[1])
                     {
                      case '\\':
                           emit ("\\");
                           break;

                      case '/':
                           emit ("/");
                           break;

                      case '"':
                           emit (`"`);
                           break;

                      case 'b':
                           emit ("\b");
                           break;

                      case 'f':
                           emit ("\f");
                           break;

                      case 'n':
                           emit ("\n");
                           break;

                      case 'r':
                           emit ("\r");
                           break;

                      case 't':
                           emit ("\t");
                           break;

                      case 'u':
                           if (len < 6)
                               goto default;
                           else
                              {
                              dchar v = 0;
                              T[6]  t = void;

                              for (auto i=2; i < 6; ++i)
                                  {
                                  auto c = s[i];
                                  if (c >= '0' && c <= '9')
                                     {}
                                  else
                                     if (c >= 'a' && c <= 'f')
                                         c -= 39;
                                     else
                                        if (c >= 'A' && c <= 'F')
                                            c -= 7;
                                        else
                                           goto default;
                                  v = (v << 4) + c - '0';
                                  }
                              
                              emit (Utf.fromString32 ((&v)[0..1], t));
                              len -= 4;
                              s += 4;
                              }
                           break;

                      default:
                           throw new Exception ("invalid escape");
                     }

              s += 2;
              len -= 2;           
              } while ((delta = Util.indexOf (s, slash, len)) < len);

           // copy tail too
           emit (s [0 .. len]);
           }
        else
           emit (src);
}


/******************************************************************************

        Convert reserved chars to escaped ones. For example: \ => \\ 

        Either a slice of the provided output buffer is returned, or the 
        original content, depending on whether there were reserved chars
        present or not. The output buffer should be at least twice the 
        length of the provided src, or it will be allocated from the heap 
        instead 
        
******************************************************************************/

T[] escape(T) (T[] src, T[] dst = null)
{
        auto s = src.ptr;
        auto t = s;
        auto e = s + src.length;

        // make some room if not enough provided
        if (dst.length < src.length * 2)
            dst.length = src.length * 2;
        auto d = dst.ptr;

        while (s < e)
              {
              if (*s is '"' || *s is '/' || *s is '\\')
                 {
                 auto len = s - t;
                 d [0 .. len] = t [0 .. len];
                 d += len;
                 *d++ = '\\';
                 t = s;
                 }
              ++s;           
              }

        // did we change anything?
        if (d > dst.ptr)
           {
           // copy tail too
           auto len = e - t;
           d [0 .. len] = t [0 .. len];
           return dst [0 .. d  + len - dst.ptr];
           }

        return src;
}


/******************************************************************************

        Convert reserved chars to escaped ones. For example: \ => \\ 

        This variant does not require an interim workspace, and instead
        emits directly via the provided delegate
        
******************************************************************************/

void escape(T) (T[] src, void delegate(T[]) emit)
{
        auto s = src.ptr;
        auto t = s;
        auto e = s + src.length;
        auto escaped = false;

        while (s < e)
              {
              if (*s is '"' || *s is '/' || *s is '\\')
                 {
                 escaped = true;
                 emit (t [0 .. s - t]);
                 emit ("\\");
                 t = s;
                 }
              ++s;           
              }

        // did we change anything? Copy tail also
        if (escaped)
            emit (t [0 .. e - t]);
        else
           emit (src);
}


/******************************************************************************

******************************************************************************/

debug (JsonEscape)
{
        import tango.io.Stdout;

        void main()
        {
                escape ("abc");
                assert (escape ("abc") == "abc");
                assert (escape ("/abc") == "\\/abc", escape ("/abc"));
                assert (escape ("ab\\c") == "ab\\\\c", escape ("ab\\c"));
                assert (escape ("abc\"") == "abc\\\"");
                assert (escape ("abc/") == "abc\\/");

                unescape ("abc");
                unescape ("abc\\u0020x", cast(void delegate(char[])) &Stdout.stream.write);
                assert (unescape ("abc") == "abc");
                assert (unescape ("abc\\") == "abc\\");
                assert (unescape ("abc\\t") == "abc\t");
                assert (unescape ("abc\\tc") == "abc\tc");
                assert (unescape ("\\t") == "\t");
                assert (unescape ("\\tx") == "\tx");
                assert (unescape ("\\r\\rx") == "\r\rx");
                assert (unescape ("abc\\t\\n\\bc") == "abc\t\n\bc");

                assert (unescape ("abc\"\\n\\bc") == "abc\"\n\bc");
                assert (unescape ("abc\\u002bx") == "abc+x");
        }

}

