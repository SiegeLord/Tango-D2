/*******************************************************************************

        Copyright: Copyright (C) 2008 Aaron Craelius & Kris Bell
                   All rights reserved

        License:   BSD style: $(LICENSE)

        version:   July 2008: Initial release

        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.json.Json;

private import core.vararg;
private import tango.io.model.IConduit;
private import tango.text.json.JsonEscape;
private import tango.text.json.JsonParser;
private import Float = tango.text.convert.Float;

/*******************************************************************************

        Parse json text into a set of inter-related structures. Typical 
        usage is as follows:
        ---
        auto json = new Json!(char);
        json.parse (`{"t": true, "n":null, "array":["world", [4, 5]]}`);    
        ---   

        Converting back to text format employs a delegate. This one emits 
        document content to the console:
        ---
        json.print ((char[] s) {Stdout(s);}); 
        ---

        Constructing json within your code leverages a handful of factories 
        within a document instance. This example creates a document from an 
        array of values:
        ---
        auto json = new Json!(char);

        // [true, false, null, "text"]
        with (json)
              value = array (true, false, null, "text");
        ---

        Setting the document to contain a simple object instead:
        ---
        // {"a" : 10}
        with (json)
              value = object (pair("a", value(10)));
        ---

        Objects may be constructed with multiple attribute pairs like so:
        ---
        // {"a" : 10, "b" : true}
        with (json)
              value = object (pair("a", value(10)), pair("b", value(true)));
        ---

        Substitute arrays, or other objects as values where appropriate:
        ---
        // {"a" : [10, true, {"b" : null}]}
        with (json)
              value = object (pair("a", array(10, true, object(pair("b")))));
        ---

        TODO: document how to extract content

        Big thanks to dhasenan for suggesting the construction notation. We
        can't make effective use of operator-overloading, due to the use of
        struct pointers, so this syntax turned out to be the next best thing.

*******************************************************************************/

class Json(T) : private JsonParser!(T)
{
        /// use these types for external references
        public alias JsonValue*  Value;
        public alias NameValue*  Attribute;
        public alias JsonObject* Composite;

        /// enumerates the seven acceptable JSON value types
        public enum Type {Null, String, RawString, Number, Object, Array, True, False};

        private Value root;

        /***********************************************************************
        
                Construct a json instance, with a default value of null

        ***********************************************************************/
        
        this ()
        {
                arrays.length = 16;
                parse (null);
        }

        /***********************************************************************
        
                Parse the given text and return a resultant Value type. Also
                sets the document value. 

        ***********************************************************************/
        
        final Value parse (const(T)[] json)
        {
            nesting = 0;
            attrib.reset;
            values.reset;
            objects.reset;
            foreach (ref p; arrays)
                p.index = 0;
        
            root = createValue;
            if (super.reset (json)) {
                if (curType is Token.BeginObject) {
                    root.set (parseObject);
                } else {
                    if (curType is Token.BeginArray)
                        root.set (parseArray);
                    else
                        throw new Exception ("invalid json document");
                }
            }
            return root;
        }
        
        /***********************************************************************

                Emit a text representation of this document to the given
                delegate

        ***********************************************************************/

        final void print (void delegate(const(T)[]) append, T[] separator = null)
        {
                root.print (append, separator);
        }

        /***********************************************************************
        
                Return a text representation of this document

        ***********************************************************************/

        final T[] toString (const(T)[] space=null, int decimals=2)
        {
                return root.print (space, decimals);
        }

        /***********************************************************************
        
                Returns the root value of this document

        ***********************************************************************/
        
        final Value value ()
        {
                return root;
        }

        /***********************************************************************
        
                Set the root value of this document

        ***********************************************************************/
        
        final Value value (Value v)
        {
                return root = v;
        }

        /***********************************************************************
        
                Create a text value

        ***********************************************************************/
        
        final Value value (const(T)[] v)
        {
                return createValue.set (v);
        }

        /***********************************************************************
        
                Create a boolean value

        ***********************************************************************/
        
        final Value value (bool v)
        {
                return createValue.set (v);
        }

        /***********************************************************************
        
                Create a numeric value

        ***********************************************************************/
        
        final Value value (double v)
        {
                return createValue.set (v);
        }

         /***********************************************************************
         
                 Create a single Value from an array of Values

         ***********************************************************************/

         final Value value (Value[] vals)
         {
                 return createValue.set (vals);
         }

        /***********************************************************************
        
                Create an array of values

        ***********************************************************************/

        final Value array (...)
        {
                return createValue.set (this, _arguments, _argptr);
        }
        
        /***********************************************************************
        
                Create a text array

        ***********************************************************************/
        
        
        final Value array(const(T)[][] values)
        {
                Value[] list;
                foreach(value; values)
                    list ~= createValue.set(value);
                return createValue.set(list);
        }

        /***********************************************************************
        
                Create an attribute/value pair, where value defaults to 
                null

        ***********************************************************************/
        
        Attribute pair (const(T)[] name, Value value = null)
        {
                if (value is null)
                    value = createValue;
                return createAttribute.set (name, value);
        }

        /***********************************************************************
        
                Create a composite from zero or more pairs, and return as 
                a value

        ***********************************************************************/
        
        final Value object (Attribute set[]...)
        {
                return createValue.set (createObject.add (set));
        }

        /***********************************************************************
        
                Internal factory to create values

        ***********************************************************************/
        
        private Value createValue ()
        {
                return values.allocate.reset;
        }

        /***********************************************************************
        
                Internal factory to create composites

        ***********************************************************************/
        
        private Composite createObject ()
        {
                return objects.allocate.reset;
        }

        /***********************************************************************
        
                Internal factory to create attributes

        ***********************************************************************/
       
        private Attribute createAttribute ()
        {
                return attrib.allocate;
        }

        /***********************************************************************
        
                Parse an instance of a value

        ***********************************************************************/
        
        private Value parseValue ()
        {
                JsonValue* v = this.values.allocate;

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
        
                Parse an object declaration

        ***********************************************************************/
        
        private Composite parseObject ()
        {
                auto o = objects.allocate.reset;

                while (super.next) 
                      {
                      if (super.curType is Token.EndObject)
                          return o;

                      if (super.curType != Token.Name)
                          super.expected ("an attribute-name", super.str.ptr);
                        
                      auto name = super.value;
                        
                      if (! super.next)
                            super.expected ("an attribute-value", super.str.ptr);
                        
                      o.append (attrib.allocate.set (name, parseValue));
                      }

                return o;
        }
        
        /***********************************************************************
        
                Parse an array declaration

        ***********************************************************************/
        
        private Value[] parseArray ()
        {
                if (nesting >= arrays.length)
                    throw new Exception ("array nesting too deep within document");

                auto array = &arrays[nesting++];
                auto start = array.index;

                while (super.next && super.curType != Token.EndArray) 
                      {
                      if (array.index >= array.content.length)
                          array.content.length = array.content.length + 300;

                      array.content [array.index++] = parseValue;
                      }

                if (super.curType != Token.EndArray)
                    throw new Exception ("malformed array");

                --nesting;
                return array.content [start .. array.index];
        }

        /***********************************************************************
        
                Represents an attribute/value pair. Aliased as Attribute

        ***********************************************************************/
        
        struct NameValue
        {
                private Attribute       next;
                public  const(T)[]      name;
                public  Value           value;

                /***************************************************************
        
                        Set a name and a value for this attribute

                        Returns itself, for use with Composite.add()

                ***************************************************************/
        
                Attribute set (const(T)[] key, Value val)
                {
                        name = key.dup;
                        value = val;
                        return &this;
                }
        }

        /***********************************************************************

                Represents a single json Object (a composite of named 
                attribute/value pairs).

                This is aliased as Composite

        ***********************************************************************/
        
        struct JsonObject
        {
                private Attribute head,
                                  tail;
                
                /***************************************************************
        
                ***************************************************************/
        
                Composite reset ()
                {
                        head = tail = null;
                        return &this;
                }

                /***************************************************************
        
                        Append an attribute/value pair

                ***************************************************************/
        
                Composite append (Attribute a)
                {
                        if (tail)
                            tail.next = a, tail = a;
                        else
                           head = tail = a;
                        return &this;
                }

                /***************************************************************
        
                        Add a set of attribute/value pairs

                ***************************************************************/
        
                Composite add (Attribute[] set...)
                {
                        foreach (attr; set)
                                 append (attr);
                        return &this;
                }

                /***************************************************************
                        
                        Construct and return a hashmap of Object attributes.
                        This will be a fairly costly operation, so consider 
                        alternatives where appropriate

                ***************************************************************/
        
                Value[T[]] hashmap ()
                {
                        Value[T[]] members;

                        auto a = head;
                        while (a)
                              {
                              members[a.name.idup] = a.value;
                              a = a.next;
                              }

                        return members;
                }
        
                /***************************************************************
        
                        Return a corresponding value for the given attribute 
                        name. Does a linear lookup across the attribute set

                ***************************************************************/
        
                Value value (const(T)[] name)
                {
                        auto a = head;
                        while (a)
                               if (name == a.name)
                                   return a.value;
                               else
                                  a = a.next;

                        return null;
                }
        
                /***************************************************************
        
                        Iterate over our attribute names and values

                ***************************************************************/
        
                Iterator attributes ()
                {
                        Iterator i = {head};
                        return i;
                }

                /***************************************************************
        
                        Iterate over our attribute names. Note that we 
                        use a Fruct to handle this, since foreach does
                        not operate cleanly with pointers (it doesn't 
                        automatically dereference them), whereas using 
                        x.attributes() does. 
                        
                        We may also use this to do some name filtering

                ***************************************************************/
        
                static struct Iterator
                {
                        private Attribute head;
        
                        int opApply (int delegate(ref const(T)[] key, ref Value val) dg)
                        {
                                int res;
        
                                auto a = head;
                                while (a)
                                      {
                                      if ((res = dg (a.name, a.value)) != 0) 
                                           break;
                                      a = a.next;
                                      }
                               return res;
                        }
                }
        }
        
        /***********************************************************************
        
                Represents a json value that is one of the seven types 
                specified via the Json.Type enum 

        ***********************************************************************/
        
        struct JsonValue
        {
                private union
                {
                        Value[]         array;
                        real            number;
                        const(T)[]      string;
                        Composite       object;
                }
        
                public Type type;               /// the type of this node
                alias reset set;                /// alternate name for reset

                /***************************************************************
        
                        return true if this node is of the given type

                ***************************************************************/
        
                const bool opEquals(ref const(JsonValue) t)
                {
                        return this.type is t.type;
                }
                
                /***************************************************************
        
                        Return true if this value represent True

                ***************************************************************/
        
                bool toBool ()
                {
                        return (type is Type.True);
                }

                /***************************************************************
                        
                        Return the string content. Returns null if this
                        value is not a string.

                        Uses dst for escape conversion where possible.

                ***************************************************************/
        
                const(T)[] toString (T[] dst = null)
                {
                        if (type is Type.RawString)
                            /* bad dup */
                            return string.dup;

                        if (type is Type.String)
                            return unescape (string, dst);

                        return null;
                }
                
                /***************************************************************
        
                        Emit the string content to the given delegate, with
                        escape conversion as required.

                        Returns false if this is not a String value
                      
                ***************************************************************/
        
                bool toString (void delegate(const(T)[]) dg)
                {
                        if (type is Type.RawString)
                            dg(string);
                        else
                           if (type is Type.String)
                               unescape (string, dg);
                           else
                              return false;
                        return true;
                }

                /***************************************************************
        
                        Return the content as a Composite/Object. Returns null
                        if this value is not a Composite.

                ***************************************************************/
        
                Composite toObject ()
                {
                        return type is Type.Object ? object : null;
                }
                
                /***************************************************************
        
                        Return the content as a double. Returns nan where
                        the value is not numeric.

                ***************************************************************/
        
                real toNumber ()
                {
                        return type is Type.Number ? number : real.nan;
                }
                
                /***************************************************************
        
                        Return the content as an array. Returns null where
                        the value is not an array.

                ***************************************************************/
        
                Value[] toArray ()
                {
                        return (type is Type.Array) ? array : null;
                }
                
                /***************************************************************
        
                        Set this value to represent a string. If 'escaped' 
                        is set, the string is assumed to have pre-converted
                        escaping of reserved characters (such as \t).

                ***************************************************************/
        
                Value set (const(T)[] str, bool escaped = false)
                {
                        type = escaped ? Type.String : Type.RawString;
                        string = str.dup;
                        return &this;
                }
                
                /***************************************************************
        
                        Set this value to represent an object.

                ***************************************************************/
        
                Value set (Composite obj)
                {
                        type = Type.Object;
                        object = obj;
                        return &this;
                }
                
                /***************************************************************
        
                        Set this value to represent a number.

                ***************************************************************/
        
                Value set (real num)
                {
                        type = Type.Number;
                        number = num;
                        return &this;
                }
                
                /***************************************************************
        
                        Set this value to represent a boolean.

                ***************************************************************/
        
                Value set (bool b)
                {
                        type = b ? Type.True : Type.False;             
                        return &this;
                }
                
                /***************************************************************
        
                        Set this value to represent an array of values.

                ***************************************************************/
        
                Value set (Value[] a)
                {
                        type = Type.Array;
                        array = a;
                        return &this;
                }
                
                /***************************************************************
        
                        If this is an array, then you can append Values

                ***************************************************************/
                
                Value append(Value a)
                {
                    if(type is Type.Array)
                        array ~= a;
                    return &this;
                }
                
                /***************************************************************
        
                        Set this value to represent null

                ***************************************************************/
        
                Value reset ()
                {
                        type = Type.Null;
                        return &this;
                }
                
                /***************************************************************
        
                        Return a text representation of this value

                ***************************************************************/

                T[] print (const(T)[] space=null, int decimals=2)
                {
                        T[] tmp;
                        void append (const(T)[] s) {tmp ~= s.dup;}
                        print (&append, space, decimals);
                        return tmp;
                }

                /***************************************************************
        
                        Emit a text representation of this value to the 
                        given OutputStream

                ***************************************************************/

                Value print (OutputStream s, const(T)[] space=null, int decimals=2)
                {
                        return print ((const(T)[] t){s.write(t);}, space, decimals);
                }

                /***************************************************************
                        
                        Emit a text representation of this value to the
                        provided delegate

                ***************************************************************/
                
                Value print (void delegate(const(T)[]) append, const(T)[] space=null, int decimals=2)
                {
                        auto indent = 0;
        
                        void newline ()
                        {
                                if (space.length)
                                   {
                                   append ("\n");
                                   for (auto i=0; i < indent; i++)
                                        append (space);
                                   }
                        }
        
                        void printValue (Value val)
                        {
                                void printObject (Composite obj)
                                {
                                        if (obj is null) 
                                            return;
                                        
                                        bool first = true;
                                        append ("{");
                                        indent++;
        
                                        foreach (k, v; obj.attributes)
                                                {
                                                if (!first)  
                                                     append (",");
                                                newline;
                                                append (`"`), append(k), append(`":`);
                                                printValue (v);
                                                first = false;
                                                }
                                        indent--;
                                        newline;
                                        append ("}");
                                }
                                
                                void printArray (Value[] arr)
                                {
                                        bool first = true;
                                        append ("[");
                                        indent++;
                                        foreach (v; arr)
                                                {
                                                if (!first) 
                                                     append (", ");
                                                newline;
                                                printValue (v);
                                                first = false;
                                                }
                                        indent--;
                                        newline;
                                        append ("]");
                                }
        
        
                                if (val is null) 
                                    return;
                                
                                T[64] tmp = void;
                                switch (val.type)
                                {
                                    case Type.String:
                                        append (`"`), append(val.string), append(`"`);
                                        break;

                                    case Type.RawString:
                                        append (`"`), escape(val.string, append), append(`"`);
                                        break;

                                    case Type.Number:
                                        append (Float.format (tmp, val.toNumber, decimals));
                                        break;

                                    case Type.Object:
                                        auto obj = val.toObject;
                                        debug assert(obj !is null);
                                        printObject (val.toObject);
                                        break;

                                    case Type.Array:
                                        printArray (val.toArray);
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
                        
                        printValue (&this);
                        return &this;
                }

                /***************************************************************
        
                        Set to a specified type

                ***************************************************************/
        
                private Value set (Type type)
                {
                        this.type = type;
                        return &this;
                }

                /***************************************************************
        
                        Set a variety of values into an array type

                ***************************************************************/
        
                private Value set (Json host, TypeInfo[] info, va_list args)
                {
                        Value[] list;

                        foreach (type; info)
                                {
                                Value v;
                                if (type is typeid(Value))
                                    v = va_arg!(Value)(args);
                                else
                                   {
                                   v = host.createValue;
                                   if (type is typeid(double))
                                       v.set (va_arg!(double)(args));
                                   else
                                   if (type is typeid(int))
                                       v.set (va_arg!(int)(args));
                                   else
                                   if (type is typeid(bool))
                                       v.set (va_arg!(bool)(args));
                                   else
                                   if (type is typeid(long))
                                       v.set (va_arg!(long)(args));
                                   else
                                   if (type is typeid(Composite))
                                       v.set (va_arg!(Composite)(args));
                                   else
                                   if (type is typeid(T[]))
                                       v.set (va_arg!(T[])(args));
                                   else
                                   if (type is typeid(const(T)[]))
                                        v.set (va_arg!(const(T)[])(args));
                                   else
                                   if (type is typeid(immutable(T)[]))
                                        v.set (va_arg!(immutable(T)[])(args));
                                   else
                                   if (type is typeid(void*))
                                       va_arg!(void*)(args);
                                   else
                                      throw new Exception ("JsonValue.set :: unexpected type: "~type.toString);
                                   }
                                list ~= v;
                                }
                                
                                
                        this.type = Type.Array;
                        this.array = list;
                        return &this;
                }
        }

        /***********************************************************************
        
                Internal allocation mechanism

        ***********************************************************************/
        
        private struct Allocator(T)
        {
                private T[]     list;
                private T[][]   lists;
                private int     index,
                                block;

                void reset ()
                {
                        // discard since prior lists are not initialized
                        lists.length = 0;       
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
                           lists[$-1] = new T[256];
                           }
                        list = lists [block];
                }
        }

        /***********************************************************************
            
                Internal use for parsing array values
                    
        ***********************************************************************/
        
        private struct Array
        {
                uint            index;
                Value[]         content;
        }

        /***********************************************************************
        
                Internal document representation

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



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        unittest
        {
            with (new Json!(char))
            {
                root = object
                (
                    pair ("edgar", value("friendly")),
                    pair ("count", value(11.5)),
                    pair ("array", value(array(1, 2)))
                );

            char[] value = toString();
            assert (value == `{"edgar":"friendly","count":11.5,"array":[1, 2]}`, value);
            }
        }
        
        unittest
        {
        // check with a separator of the tab character
        with (new Json!(char))
             {
             root = object
                  (
                  pair ("edgar", value("friendly")),
                  pair ("count", value(11.5)),
                  pair ("array", value(array(1, 2)))
                  );

             const(char)[] value = toString ("\t");
             assert (value == "{\n\t\"edgar\":\"friendly\",\n\t\"count\":11.5,\n\t\"array\":[\n\t\t1, \n\t\t2\n\t]\n}", value);
             }
        }
        
        unittest
        {
        // check with a separator of five spaces
        with (new Json!(dchar))
             {
             root = object
                  ( 
                  pair ("edgar", value("friendly")),
                  pair ("count", value(11.5)),
                  pair ("array", value(array(1, 2)))
                  );

             dchar[] value = toString ("     ");
             assert (value == "{\n     \"edgar\":\"friendly\",\n     \"count\":11.5,\n     \"array\":[\n          1, \n          2\n     ]\n}");
             }
        }
}
        
/*******************************************************************************

*******************************************************************************/

debug (Json)
{
        import tango.io.Stdout;
        import tango.io.device.File;
        import tango.time.StopWatch;
                
        void main()
        {
                void loop (JsonParser!(char) parser, char[] json, int n)
                {
                        for (uint i = 0; i < n; ++i)
                            {
                            parser.reset (json);
                            while (parser.next) {}
                            }
                }
        
                void test (char[] filename, char[] txt)
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
        
                void test1 (char[] filename, char[] txt)
                {
                        uint n = (200 * 1024 * 1024) / txt.length;
                        auto parser = new Json!(char);
                        
                        StopWatch watch;
                        watch.start;
                        for (uint i = 0; i < n; ++i)
                             parser.parse (txt);
        
                        auto t = watch.stop;
                        auto mb = (txt.length * n) / (1024 * 1024);
                        Stdout.formatln("{} {} iterations, {} seconds: {} MB/s", filename, n, t, mb/t);
                }
        
                char[] load (char[] file)
                {
                        return cast(char[]) File.get(file);
                }
        
                //test("test1.json", load("test1.json"));
                //test("test2.json", load("test2.json"));
                //test("test3.json", load("test3.json"));
                        
                //test1("test1.json", load("test1.json"));
                //test1("test2.json", load("test2.json"));
                //test1("test3.json", load("test3.json"));
                
                auto p = new Json!(char);
                auto v = p.parse (`{"t": true, "f":false, "n":null, "hi":["world", "big", 123, [4, 5, ["foo"]]]}`);       
                Stdout.formatln ("{}", p.toString);
        
                with (p)
                      value = object(pair("a", array(null, true, false, 30, object(pair("foo")))), pair("b", value(10)));
        
                Stdout.formatln ("{}", p.toString);

                p.parse ("[-1]");
                Stdout.formatln ("{}", p.toString(null));

                p.parse ("[11.23477]");
                Stdout.formatln ("{}", p.toString(null, 4));

                p.parse(`["foo"]`);
                Stdout.formatln ("{}", p.toString);

                p.parse(`{"foo": {"ff" : "ffff"}`);
                Stdout.formatln ("{}", p.toString);

                with (new Json!(char))
                     {
                     root = object(pair("array", array(null)));
                     Stdout.formatln ("{}", toString());
                     }
        }
}



