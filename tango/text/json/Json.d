/*******************************************************************************

        Copyright: Copyright (C) 2008 Aaron Craelius & Kris Bell
                   All rights reserved

        License:   BSD style: $(LICENSE)

        version:   July 2008: Initial release

        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.json.Json;

private import tango.text.json.JsonEscape;

private import tango.text.json.JsonParser;

private import Float = tango.text.convert.Float;



/**
 * Enumerates the seven acceptable JSON value types.
 */
/**
 * Represents a JSON value that is one of the seven types specified by the enum
 * Type.
 */
/**
 * Represents a single JSON Object.
 */

/*******************************************************************************

*******************************************************************************/

class Json(T) : private JsonParser!(T)
{
        public alias JsonValue*  Value;
        public alias NameValue*  Attribute;
        public alias JsonObject* Composite;

        public enum Type {Null, String, RawString, Number, Object, Array, True, False};

        /***********************************************************************
        
        ***********************************************************************/
        
        this ()
        {
                arrays.length = 16;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        public Value parse (T[] json)
        {

                nesting = 0;
                attrib.reset;
                values.reset;
                objects.reset;
                foreach (ref p; arrays)
                         p.index = 0;

                super.reset (json);

                auto v = values.allocate.reset;

                if (super.next)
                    if (curType is Token.BeginObject)
                        v.set (parseObject);
                    else
                       if (curType is Token.BeginArray)
                           v.set (parseArray);
                       else
                          exception ("invalid json document");
                return v;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        public Value createValue ()
        {
                return values.allocate.reset;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        public Composite createObject ()
        {
                return objects.allocate.reset;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        public Attribute createAttribute ()
        {
                return attrib.allocate;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private void exception (char[] msg)
        {
                throw new Exception (msg);
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private Value parseValue ()
        {
                auto v = values.allocate;

                switch (super.curType)
                       {
                       case Token.True:
                            v.set (Type.True);
                            break;

                       case Token.False:
                            v.set (Type.False);
                            break;

                       case Token.Null:
                            v.set (Type.Null);
                            break;

                       case Token.BeginObject:
                            v.set (parseObject);
                            break;

                       case Token.BeginArray:
                            v.set (parseArray);
                            break;

                       case Token.String:
                            v.set (super.value, true);
                            break;

                       case Token.Number:
                            v.set (Float.parse (super.value));
                            break;

                       default:
                            v.set (Type.Null);
                            break;
                       }

                return v;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private Composite parseObject ()
        {
                auto o = objects.allocate;
                o.attributes = null;

                while (super.next) 
                      {
                      if (super.curType is Token.EndObject)
                          return o;

                      if (super.curType != Token.Name)
                          exception ("missing name in document");
                        
                      auto name = super.value;
                        
                      if (! super.next)
                            exception ("missing value in document");
                        
                      o.add (attrib.allocate.set (name, parseValue));
                      }

                return o;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private Value[] parseArray ()
        {
                if (nesting >= arrays.length)
                    exception ("array nesting too deep within document");

                auto array = &arrays[nesting++];
                auto start = array.index;

                while (super.next && super.curType != Token.EndArray) 
                      {
                      if (array.index >= array.content.length)
                          array.content.length = array.content.length + 300;

                      array.content [array.index++] = parseValue;
                      }

                --nesting;
                return array.content [start .. array.index];
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private static void print (Value root, void delegate(T[]) append)
        {
                void printVal (Value val)
                {
                        void printObj (Composite obj)
                        {
                                if (obj is null) 
                                    return;
                                
                                bool first = true;
                                append ("{");

                                foreach (k, v; *obj)
                                        {
                                        if (!first)  
                                             append (",");
                                        append (`"`), append(k), append(`":`);
                                        printVal (v);
                                        first = false;
                                        }
                                append ("}");
                                
                        }
                        
                        void printArr (Value[] arr)
                        {
                                
                                bool first = true;
                                append ("[");
                                foreach (v; arr)
                                        {
                                        if (!first) 
                                             append (", ");
                                        printVal (v);
                                        first = false;
                                        }
                                append ("]");
                        }


                        if (val is null) 
                            return;
                        
                        switch (val.type)
                               {
                               T[64] tmp = void;

                               case Type.String:
                                    append (`"`), append(val.string), append(`"`);
                                    break;

                               case Type.RawString:
                                    append (`"`), escape(val.string, append), append(`"`);
                                    break;

                               case Type.Number:
                                    append (Float.format (tmp, val.toNumber));
                                    break;

                               case Type.Object:
                                    auto obj = val.toObject;
                                    debug assert(obj !is null);
                                    printObj (val.toObject);
                                    break;

                               case Type.Array:
                                    printArr (val.toArray);
                                    break;

                               case Type.True:
                                    append ("true");
                                    break;

                               case Type.False:
                                    append ("false");
                                    break;

                               default:
                               case Type.Null:
                                    append ("null");
                                    break;
                               }
                }
                
                printVal (root);
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        struct NameValue
        {
                Attribute       next;
                T[]             name;
                Value           value;

                Attribute set (T[] key, Value val)
                {
                        name = key;
                        value = val;
                        return this;
                }
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        struct JsonObject
        {
                private Attribute attributes;
                
                /***************************************************************
        
                ***************************************************************/
        
                Composite reset ()
                {
                        attributes = null;
                        return this;
                }

                /***************************************************************
        
                        Add a new attribute/value pair

                ***************************************************************/
        
                void add (Attribute a)
                {
                        a.next = attributes;
                        attributes = a;
                }

                /***************************************************************
                        
                        Construct and return a hashmap of Object attributes.
                        This will be a fairly expensive operation, so consider 
                        alternatives where appropriate

                ***************************************************************/
        
                Value[T[]] hashmap ()
                {
                        Value[T[]] members;

                        auto a = attributes;
                        while (a)
                              {
                              members[a.name] = a.value;
                              a = a.next;
                              }

                        return members;
                }
        
                /***************************************************************
        
                        Return a corresponding value for the given attribute 
                        name. Does a linear lookup across the attribute set

                ***************************************************************/
        
                Value value (T[] name)
                {
                        auto a = attributes;
                        while (a)
                               if (name == a.name)
                                   return a.value;
                               else
                                  a = a.next;

                        return null;
                }
        
                /***************************************************************
        
                        Iterate over our attribute names

                ***************************************************************/
        
                int opApply (int delegate(inout T[] key, ref Value val) dg)
                {
                        int res;
        
                        auto a = attributes;
                        while (a)
                              {
                              if ((res = dg (a.name, a.value)) != 0) 
                                   break;
                              a = a.next;
                              }
                        return res;
                }
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        struct JsonValue
        {
                union
                {
                        Value[]         array;
                        real            number;
                        T[]             string;
                        Composite       object;
                }
        
                Type type;
        
                /***************************************************************
        
                ***************************************************************/
        
                bool opEquals (Type t) 
                {
                        return type is t;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                bool toBool ()
                {
                        return (type is Type.True);
                }

                /***************************************************************
        
                ***************************************************************/
        
                void toString (void delegate(T[]) dg)
                {
                        if (type is Type.RawString)
                            dg(string);

                        if (type is Type.String)
                            unescape (string, dg);
                }

                /***************************************************************
        
                ***************************************************************/
        
                T[] toString (T[] dst = null)
                {
                        if (type is Type.RawString)
                            return string;

                        if (type is Type.String)
                            return unescape (string, dst);

                        return null;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Composite toObject ()
                {
                        return type is Type.Object ? object : null;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                real toNumber ()
                {
                        return type is Type.Number ? number : real.nan;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value[] toArray ()
                {
                        return (type is Type.Array) ? array : null;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (T[] str, bool escaped = false)
                {
                        type = escaped ? Type.String : Type.RawString;
                        string = str;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (Composite obj)
                {
                        type = Type.Object;
                        object = obj;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (real num)
                {
                        type = Type.Number;
                        number = num;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (bool b)
                {
                        type = b ? Type.True : Type.False;             
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (Value[] a)
                {
                        type = Type.Array;
                        array = a;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value set (Type type)
                {
                        this.type = type;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value reset ()
                {
                        type = Type.Null;
                        return this;
                }
                
                /***************************************************************
        
                ***************************************************************/
        
                Value print (void delegate(T[]) dg)
                {
                        Json.print (this, dg);
                        return this;
                }
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        struct Allocator(T)
        {
                private T[]     list;
                private T[][]   lists;
                private int     index,
                                block;

                void reset ()
                {
                        block = -1;
                        newlist;
                }

                T* allocate ()
                {
                        if (index >= list.length)
                            newlist;
        
                        auto p = &list [index++];
                        return p;
                }
        
                private void newlist ()
                {
                        index = 0;
                        if (++block >= lists.length)
                           {
                           lists.length = lists.length + 1;
                           lists[$-1] = new T[128];
                           }
                        list = lists [block];
                }
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        struct Array
        {
                uint            index;
                Value[]         content;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private alias Allocator!(NameValue)     Attrib;
        private alias Allocator!(JsonValue)     Values;
        private alias Allocator!(JsonObject)    Objects;

        private Attrib                          attrib;
        private Values                          values;
        private Array[]                         arrays;
        private Objects                         objects;
        private uint                            nesting;
}






debug (Json)
{
        
import tango.io.Stdout;
import tango.io.File;
import tango.time.StopWatch;
        
void main()
{
        void loop (JsonParser!(char) parser, char[] json, int n)
        {
                for(uint i = 0; i < n; ++i)
                {
                        parser.reset (json);
                        while (parser.next) {}
                }
        }

        void test(char[] filename, char[] txt)
        {
                uint n = (300 * 1024 * 1024) / txt.length;
                auto parser = new JsonParser!(char);
                
                StopWatch watch;
                watch.start;
                loop (parser, txt, n);
                auto t = watch.stop;
                auto mb = (txt.length * n) / (1024 * 1024);
                Stdout.formatln("{} {} iterations, {} seconds: {} MB/s", filename, n, t, mb/t);
        }

        void test1(char[] filename, char[] txt)
        {
                uint n = (200 * 1024 * 1024) / txt.length;
                auto parser = new Json!(char);
                
                StopWatch watch;
                watch.start;
                for(uint i = 0; i < n; ++i)
                {
                        parser.parse (txt);
                }

                auto t = watch.stop;
                auto mb = (txt.length * n) / (1024 * 1024);
                Stdout.formatln("{} {} iterations, {} seconds: {} MB/s", filename, n, t, mb/t);
        }

        char[] load (char[] file)
        {
                auto f = new File (file);
                return cast(char[]) f.read;
        }

        //test("test1.json", load("test1.json"));
        //test("test2.json", load("test2.json"));
        //test("test3.json", load("test3.json"));
                
        //test1("test1.json", load("test1.json"));
        //test1("test2.json", load("test2.json"));
        //test1("test3.json", load("test3.json"));
        
        auto p = new Json!(char);
        auto v = p.parse (`{"t": true, "f":false, "n":null, "hi":["world", "big", 123, [4, 5, ["foo"]]]}`);       
        void emit (char[] s) {Stdout(s);}
        v.print (&emit); 
        Stdout.newline;
}

unittest
{
        //benchmark;
        
        auto p = new Json!(char);
        auto obj = p.parse(json).toObject;

        //assert(obj.members[0].name == "glossary");
        //assert(obj.members[0].value.type == Type.Object);

        assert(obj.hashmap["glossary"] != null);
        assert(obj.hashmap["glossary"].type == p.Type.Object);
        auto o = obj.value("glossary").toObject;
        //assert(o.members[0].name == "title");
        //assert(o.members[1].name == "GlossDiv");
        assert("title" in o.hashmap);
        assert("GlossDiv" in o.hashmap);
        o = o.hashmap["GlossDiv"].toObject;
        //assert(o.members[0].name == "title");
        //assert(o.members[1].name == "GlossList");
        
        assert("title" in o.hashmap);
        assert("GlossList" in o.hashmap);
}
}


