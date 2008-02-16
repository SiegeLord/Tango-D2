/*******************************************************************************
 
        Copyright: Copyright (C) 2007 Aaron Craelius and Kris Bell.  
                   All rights reserved.

        License:   BSD Style
        Authors:   Aaron Craelius and Kris Bell

*******************************************************************************/

module tango.text.xml.PullParser;

private import tango.text.xml.XmlIterator;

private import Integer = tango.text.convert.Integer;

/*******************************************************************************

*******************************************************************************/

public enum XmlNodeType {Element, Data, Attribute, CData, 
                         Comment, PI, Doctype, Document};

/*******************************************************************************

*******************************************************************************/

public enum XmlTokenType {StartElement, Attribute, EndElement, 
                          EndEmptyElement, Data, Comment, CData, 
                          Doctype, PI, None};


/*******************************************************************************

        Token based XML Parser.  Works with char[], wchar[], and dchar[] 
        based Xml strings. 

        Acknowledgements:

        This parser was inspired by VTD-XML and Marcin Kalicinski's RapidXml 
        parser.  Thanks to the RapidXml project for the lookup table idea.  
        We have used a few similar lookup tables to implement this parser. 
        Also the idea of not copying the source string but simply referencing 
        it is used here. IXmlTokenIterator doesn't implement the same interface 
        as VTD-XML, but  the spirit is similar. Thank you for your work!

*******************************************************************************/

class PullParser(Ch = char)
{
        public int                      depth;
        public Ch[]                     prefix;    
        public Ch[]                     rawValue;
        public Ch[]                     localName;     
        public XmlTokenType             type = XmlTokenType.None;

        private XmlIterator!(Ch)        text;
        private bool                    err;
        private char[]                  errMsg;
        private static Object           dummy;

        /***********************************************************************
        
                Adding this static-ctor gains another 20MB/s

                Go figure ...

        ***********************************************************************/

        static this()
        {
                dummy = null;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        this(Ch[] content = null)
        {
                reset (content);
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doAttributeName()
        {
                auto p = text.point;
                auto q = text.eatAttrName (p);

                if (*q == ':')
                   {
                   prefix = p[0 .. q - p];
                   q = text.eatAttrName (p = q + 1);
                   localName = p[0 .. q - p];
                   }
                else 
                   {
                   prefix = null;
                   localName = p[0 .. q - p];
                   }

                type = XmlTokenType.Attribute;
                if (*q <= 32) 
                   {
                   auto e = text.end;
                   do {
                      if (++q >= e)                                      
                          return doEndOfStream;
                      } while (*q <= 32);
                   }
            
                if (*q is '=')
                    return doAttributeValue (q + 1);
                return false;
        }

        /***********************************************************************
        
        ***********************************************************************/

        private bool doEndEmptyElement()
        {
                if (text[0..2] != "/>")
                    return doUnexpected("/>");
 
                type = XmlTokenType.EndEmptyElement;
                localName = prefix = null;
                text.point += 2;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doComment()
        {
                auto p = text.point;

                while (text.good)
                      {
                      if (! text.forwardLocate('-')) 
                            return doUnexpectedEOF;

                      if (text[0..3] == "-->") 
                         {
                         rawValue = p [0 .. text.point - p];
                         type = XmlTokenType.Comment;
                         //prefix = null;
                         text.point += 3;
                         return true;
                         }
                      ++text.point;
                      }

                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doCData()
        {
                auto p = text.point;
                
                while (text.good)
                      {
                      if (! text.forwardLocate(']')) 
                            return doUnexpectedEOF;
                
                      if (text[0..3] == "]]>") 
                         {
                         type = XmlTokenType.CData;
                         rawValue = p [0 .. text.point - p];
                         //prefix = null;
                         text.point += 3;                      
                         return true;
                         }
                      ++text.point;
                      }

                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doPI()
        {
                auto p = text.point;
                text.eatElemName;
                ++text.point;

                while (text.good)
                      {
                      if (! text.forwardLocate('\?')) 
                            return doUnexpectedEOF;

                      if (text.point[1] == '>') 
                         {
                         type = XmlTokenType.PI;
                         rawValue = p [0 .. text.point - p];
                         text.point += 2;
                         return true;
                         }
                      ++text.point;
                      }
                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doDoctype()
        {
                text.eatSpace;
                auto p = text.point;
                                
                while (text.good) 
                      {
                      if (*text.point == '>') 
                         {
                         type = XmlTokenType.Doctype;
                         rawValue = p [0 .. text.point - p];
                         prefix = null;
                         ++text.point;
                         return true;
                         }
                      else 
                         if (*text.point == '[') 
                            {
                            ++text.point;
                            text.forwardLocate(']');
                            ++text.point;
                            }
                         else 
                            ++text.point;
                      }

                if (! text.good)
                      return doUnexpectedEOF;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doUnexpectedEOF()
        {
                return error ("Unexpected EOF");
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doUnexpected(char[] msg = null)
        {
                return error ("Unexpected event " ~ msg ~ " " ~ Integer.toString(type));
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool doEndOfStream()
        {
                return false;
        }
              
        /***********************************************************************
        
        ***********************************************************************/

        private bool doMain()
        {
                auto p = text.point;
                if (*p != '<') 
                   {
                   auto q = p;
                   while (++p < text.end) 
                          if (*p is '<')
                             {
                             type = XmlTokenType.Data;
                             rawValue = q [0 .. p - q];
                             text.point = p;
                             return true;
                             }
                   return doUnexpectedEOF;
                   }

                switch (p[1])
                       {
                       case '\?':
                            text.point += 2;
                            return doPI();

                       default:
                            auto q = ++p;
                            //auto e = text.end;
                            while (q < text.end)
                                  {
                                  auto c = *q;
                                  if (c > 63 || text.name[c])
                                      ++q;
                                  else
                                     break;
                                  }
                            text.point = q;

                            if (*q != ':') 
                               {
                               prefix = null;
                               localName = p [0 .. q - p];
                               }
                            else
                               {
                               prefix = p [0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               localName = p [0 .. q - p];
                               }

                            type = XmlTokenType.StartElement;
                            return true;

                       case '!':
                            if (text[2..4] == "--") 
                               {
                               text.point += 4;
                               return doComment();
                               }       
                            else 
                               if (text[2..9] == "[CDATA[") 
                                  {
                                  text.point += 9;
                                  return doCData();
                                  }
                               else 
                                  if (text[2..9] == "DOCTYPE") 
                                     {
                                     text.point += 9;
                                     return doDoctype();
                                     }
                            return doUnexpected("!");

                       case '/':
                            p += 2;
                            auto q = p;
                            auto e = text.end;
                            while (q < e)
                                  {
                                  auto c = *q;
                                  if (c > 63 || text.name[c])
                                      ++q;
                                  else
                                     break;
                                  }
                            text.point = q;

                            if (*q != ':') 
                               {
                               prefix = null;
                               localName = p[0 .. q - p];
                               }
                            else 
                               {
                               prefix = p[0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               localName = p[0 .. q - p];
                               }

                            auto end = text.end;
                            while (*q <= 32 && q <= end)
                                   ++q;

                            type = XmlTokenType.EndElement;
                            if (*q == '>')
                               {
                               text.point = q + 1;
                               --depth;
                               return true;
                               }
                            return doUnexpected(">");
                       }

               return false;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final bool next()
        {      
                auto p = text.point;
                if (*p <= 32) 
                   {
                   while (*++p <= 32)
                          if (p >= text.end)                                      
                              return doEndOfStream;
                   text.point = p;
                   }
                
                if (type >= XmlTokenType.EndElement) 
                    return doMain;

                // in element
                switch (*p)
                       {
                       case '/':
                            return doEndEmptyElement;

                       case '>':
                            ++depth;
                            ++text.point;
                            return doMain;

                       default:
                            break;
                       }
                return doAttributeName;
        }
 
        /***********************************************************************
        
        ***********************************************************************/

        private bool doAttributeValue(Ch* q)
        {
                auto p = text.eatSpace (q);
                auto quote = *p++;

                switch (quote)
                       {
                       case '"':
                       case '\'':
                            q = text.forwardLocate(p, quote);
                            rawValue = p[0 .. q - p];
                            text.point = q + 1; //Skip end quote
                            return true;

                       default: 
                            return doUnexpected("\' or \"");
                       }
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private bool error (char[] msg)
        {
                errMsg = msg;
                err = true;
                return false;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final Ch[] value()
        {
                return rawValue;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final Ch[] name()
        {
                if (prefix.length)
                    return prefix ~ ":" ~ localName;
                return localName;
        }
                
        /***********************************************************************
        
        ***********************************************************************/

        final bool error()
        {
                return err;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final bool reset()
        {
                text.seek (0);
                reset_;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final void reset(Ch[] newText)
        {
                text.reset (newText);
                reset_;                
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private void reset_()
        {
                err = false;
                depth = 0;
                type = XmlTokenType.None;

                if (text.point)
                   {
                   static if (Ch.sizeof == 1)
                   {
                       //Read UTF8 BOM
                       if (*text.point == 0xef)
                          {
                          if (text.point[1] == 0xbb)
                             {
                             if(text.point[2] == 0xbf)
                                text.point += 3;
                             }
                          }
                  }
                
                   //TODO enable optional declaration parsing
                   text.eatSpace;
                   if (*text.point == '<')
                      {
                      if (text.point[1] == '\?')
                         {
                         if (text[2..5] == "xml")
                            {
                            text.point += 5;
                            text.forwardLocate('\?');
                            text.point += 2;
                            }
                         }
                      }
                   }
        }
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
	/***********************************************************************
	
	***********************************************************************/
	
	void testParser(Ch)(PullParser!(Ch) itr)
	{
	  /*      assert(itr.next);
	        assert(itr.value == "");
	        assert(itr.type == XmlTokenType.Declaration, Integer.toString(itr.type));
	        assert(itr.next);
	        assert(itr.value == "version");
	        assert(itr.next);
	        assert(itr.value == "1.0");*/
	        assert(itr.next);
	        assert(itr.value == "element [ <!ELEMENT element (#PCDATA)>]");
	        assert(itr.type == XmlTokenType.Doctype);
	        assert(itr.next);
	        assert(itr.localName == "element");
	        assert(itr.type == XmlTokenType.StartElement);
	        assert(itr.depth == 0);
	        assert(itr.next);
	        assert(itr.localName == "attr");
	        assert(itr.value == "1");
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.Attribute, Integer.toString(itr.type));
	        assert(itr.localName == "attr2");
	        assert(itr.value == "two");
	        assert(itr.next);
	        assert(itr.value == "comment");
	        assert(itr.next);
	        assert(itr.rawValue == "test&amp;&#x5a;");
	        assert(itr.next);
	        assert(itr.prefix == "qual");
	        assert(itr.localName == "elem");
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.EndEmptyElement);
	        assert(itr.next);
	        assert(itr.localName == "el2");
	        assert(itr.depth == 1);
	        assert(itr.next);
	        assert(itr.localName == "attr3");
	        assert(itr.value == "3three", itr.value);
	        assert(itr.next);
	        assert(itr.rawValue == "sdlgjsh");
	        assert(itr.next);
	        assert(itr.localName == "el3");
	        assert(itr.depth == 2);
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.EndEmptyElement);
	        assert(itr.next);
	        assert(itr.value == "data");
	        assert(itr.next);
	      //  assert(itr.qvalue == "pi", itr.qvalue);
	      //  assert(itr.value == "test");
	        assert(itr.rawValue == "pi test");
	        assert(itr.next);
	        assert(itr.localName == "el2");
	        assert(itr.next);
	        assert(itr.localName == "element");
	        assert(!itr.next);
	}
	
	
	/***********************************************************************
	
	***********************************************************************/
	
	static const char[] testXML = "<?xml version=\"1.0\" ?><!DOCTYPE element [ <!ELEMENT element (#PCDATA)>]><element "
	    "attr=\"1\" attr2=\"two\"><!--comment-->test&amp;&#x5a;<qual:elem /><el2 attr3 = "
	    "'3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	
	unittest
	{       
	        auto itr = new PullParser!(char)(testXML);     
	        testParser (itr);
	}
}
