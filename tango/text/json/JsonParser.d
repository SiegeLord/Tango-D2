/*******************************************************************************

        Copyright: Copyright (C) 2008 Aaron Craelius & Kris Bell.  
                   All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: July 2008      

        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.json.JsonParser;

private import tango.util.container.more.Stack;

/*******************************************************************************

*******************************************************************************/

class JsonParser(T)
{
        public enum Token
               {
               Empty, Name, String, Number, BeginObject, EndObject, 
               BeginArray, EndArray, True, False, Null
               }

        private enum State {Object, Array};

        private struct Iterator
        {
                const(T)*      ptr;
                const(T)*      end;
                const(T)[]     text;

                void reset (const(T)[] text)
                {
                        this.text = text;
                        this.ptr = text.ptr;
                        this.end = ptr + text.length;
                }
        }

        protected Iterator              str;
        private Stack!(State, 16)       state;
        private const(T)*               curLoc;
        private size_t                  curLen;
        private State                   curState; 
        protected Token                 curType;
        
        /***********************************************************************
        
        ***********************************************************************/
        
        this (const(T)[] text = null)
        {
                reset (text);
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final bool next ()
        {
                if (str.ptr is null || str.end is null)
                    return false;

                auto p = str.ptr;
                auto e = str.end;


                while (*p <= 32 && p < e) 
                       ++p; 

                if ((str.ptr = p) >= e) 
                     return false;

                if (curState is State.Array) 
                    return parseArrayValue;

                switch (curType)
                       {
                       case Token.Name:
                            return parseMemberValue;

                       default:                
                            break;
                       }

                return parseMemberName;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final Token type ()
        {
                return curType;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final const(T)[] value ()
        {
                return this.curLoc [0 .. curLen];
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        bool reset (const(T)[] json = null)
        {
                state.clear;
                str.reset (json);
                curType = Token.Empty;
                curState = State.Object;

                if (json.length)
                   {
                   auto p = str.ptr;
                   auto e = str.end;

                   while (*p <= 32 && p < e) 
                          ++p; 
                   if (p < e)
                       return start (*(str.ptr = p));
                   }
                return false;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        protected final void expected (const(char)[] token)
        {
                throw new Exception(("expected " ~ token).idup);
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        protected final void expected (const(char)[] token, const(T)* point)
        {
                static char[] itoa (char[] buf, size_t i)
                {
                        auto p = buf.ptr+buf.length;
                        do {
                           *--p = '0' + i % 10;
                           } while (i /= 10);
                        return p[0..(buf.ptr+buf.length)-p];
                }
                char[16] tmp = void;
                expected (token ~ " @input[" ~ itoa(tmp, point-str.text.ptr)~"]");
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private void unexpectedEOF (const(char)[] msg)
        {
                throw new Exception (("unexpected end-of-input: " ~ msg).idup);
        }
                
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool start (T c)
        {
                if (c is '{') 
                    return push (Token.BeginObject, State.Object);

                if (c is '[') 
                    return push (Token.BeginArray, State.Array);

                expected ("'{' or '[' at start of document");
                assert(0);
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private bool parseMemberName ()
        {
                auto p = str.ptr;
                auto e = str.end;

                if(*p is '}') 
                    return pop (Token.EndObject);
                
                if(*p is ',') 
                    ++p;
                
                while (*p <= 32) 
                       ++p;

                if (*p != '"') {
                    if (*p == '}')
                        expected ("an attribute-name after (a potentially trailing) ','", p);
                    else
                       expected ("'\"' before attribute-name", p);
                }

                this.curLoc = p+1;
                this.curType = Token.Name;

                while (++p < e) 
                       if (*p is '"' && !escaped(p))
                           break;

                if (p < e) 
                    this.curLen = p - curLoc;
                else
                   unexpectedEOF ("in attribute-name");

                str.ptr = p + 1;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool parseMemberValue ()
        {
                auto p = str.ptr;

                if(*p != ':') 
                   expected ("':' before attribute-value", p);

                auto e = str.end;
                while (++p < e && *p <= 32) {}

                return parseValue (*(str.ptr = p));
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool parseValue (T c)
        {                       
                switch (c)
                       {
                       case '{':
                            return push (Token.BeginObject, State.Object);
         
                       case '[':
                            return push (Token.BeginArray, State.Array);
        
                       case '"':
                            return doString;
        
                       case 'n':
                            if (match ("null", Token.Null))
                                return true;
                            expected ("'null'", str.ptr);
							goto case;
							
                       case 't':
                            if (match ("true", Token.True))
                                return true;
                            expected ("'true'", str.ptr);
							goto case;
							
                       case 'f':
                            if (match ("false", Token.False))
                                return true;
                            expected ("'false'", str.ptr);
                            goto default;

                       default:
                            break;
                       }

                return parseNumber;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool doString ()
        {
                auto p = str.ptr;
                auto e = str.end;

                curLoc = p+1;
                curType = Token.String;
                
                while (++p < e) 
                       if (*p is '"' && !escaped(p))
                           break;

                if (p < e) 
                    curLen = p - curLoc;
                else
                   unexpectedEOF ("in string");

                str.ptr = p + 1;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool parseNumber ()
        {
                auto p = str.ptr;
                auto e = str.end;
                T c = *(curLoc = p);

                curType = Token.Number;

                if (c is '-' || c is '+')
                    c = *++p;

                while (c >= '0' && c <= '9') c = *++p;                 

                if (c is '.')
                    while (c = *++p, c >= '0' && c <= '9') {}                 

                if (c is 'e' || c is 'E')
                    while (c = *++p, c >= '0' && c <= '9') {}

                if (p < e) 
                    curLen = p - curLoc;
                else
                   unexpectedEOF ("after number");

                str.ptr = p;
                return curLen > 0;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool match (const(T)[] name, Token token)
        {
                auto i = name.length;
                if (str.ptr[0 .. i] == name)
                   {
                   curLoc = str.ptr;
                   curType = token;
                   str.ptr += i;
                   curLen = i;
                   return true;
                   }
                return false;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool push (Token token, State next)
        {
                curLen = 0;
                curType = token;
                curLoc = str.ptr++;
                state.push (curState);
                curState = next;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private bool pop (Token token)
        {
                curLen = 0;
                curType = token;
                curLoc = str.ptr++;
                curState = state.pop;
                return true;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private bool parseArrayValue ()
        {
                auto p = str.ptr;
                if (*p is ']') 
                    return pop (Token.EndArray);
                
                if (*p is ',') 
                    ++p;

                auto e = str.end;
                while (p < e && *p <= 32) 
                       ++p;

                return parseValue (*(str.ptr = p));
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private int escaped (const(T)* p)
        {
                int i;

                while (*--p is '\\')
                       ++i;
                return i & 1;
        }
}



debug(UnitTest)
{       
                const static char[] json = 
                "{"
                        "\"glossary\": {"
                        "\"title\": \"example glossary\","
                                "\"GlossDiv\": {"
                                " 	\"title\": \"S\","
                                "	\"GlossList\": {"
                                "       \"GlossEntry\": {"
                                "           \"ID\": \"SGML\","
                                "			\"SortAs\": \"SGML\","
                                "			\"GlossTerm\": \"Standard Generalized Markup Language\","
                                "			\"Acronym\": \"SGML\","
                                "			\"Abbrev\": \"ISO 8879:1986\","
                                "			\"GlossDef\": {"
                        "                \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\","
                                "				\"GlossSeeAlso\": [\"GML\", \"XML\"]"
                        "            },"
                                "			\"GlossSee\": \"markup\","
                                "			\"ANumber\": 12345.6e7"
                                "			\"True\": true"
                                "			\"False\": false"
                                "			\"Null\": null"
                        "        }"
                                "    }"
                        "}"
                    "}"
                "}";
       
unittest
{
        auto p = new JsonParser!(char)(json);
        assert(p);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "glossary", p.value);
        assert(p.next);
        assert(p.value == "", p.value);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "title", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "example glossary", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossDiv", p.value);
        assert(p.next);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "title", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "S", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossList", p.value);
        assert(p.next);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossEntry", p.value);
        assert(p.next);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "ID", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "SGML", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "SortAs", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "SGML", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossTerm", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "Standard Generalized Markup Language", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "Acronym", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "SGML", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "Abbrev", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "ISO 8879:1986", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossDef", p.value);
        assert(p.next);
        assert(p.type == p.Token.BeginObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "para", p.value);
        assert(p.next);

        assert(p.type == p.Token.String);
        assert(p.value == "A meta-markup language, used to create markup languages such as DocBook.", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossSeeAlso", p.value);
        assert(p.next);
        assert(p.type == p.Token.BeginArray);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "GML", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "XML", p.value);
        assert(p.next);
        assert(p.type == p.Token.EndArray);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "GlossSee", p.value);
        assert(p.next);
        assert(p.type == p.Token.String);
        assert(p.value == "markup", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "ANumber", p.value);
        assert(p.next);
        assert(p.type == p.Token.Number);
        assert(p.value == "12345.6e7", p.value);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "True", p.value);
        assert(p.next);
        assert(p.type == p.Token.True);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "False", p.value);
        assert(p.next);
        assert(p.type == p.Token.False);
        assert(p.next);
        assert(p.type == p.Token.Name);
        assert(p.value == "Null", p.value);
        assert(p.next);
        assert(p.type == p.Token.Null);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(p.next);
        assert(p.type == p.Token.EndObject);
        assert(!p.next);

        assert(p.state.size == 0);

}

}


debug (JsonParser)
{
        void main()
        {
                auto json = new JsonParser!(char);
        }
}

