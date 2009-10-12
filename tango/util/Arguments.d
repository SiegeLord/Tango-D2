/*******************************************************************************

        copyright:      Copyright (c) 2009 Kris. All rights reserved.

        license:        BSD style: $(LICENSE)
        
        version:        Oct 2009: Initial release
        
        author:         Kris
    
*******************************************************************************/

module tango.util.Arguments;

private import tango.text.Util;

/*******************************************************************************

        Command-line argument parser. Simple usage is:
        ---
        auto args = new Arguments;
        args.parse ("-a -b", true);
        auto a = args("a");
        auto b = args("b");
        if (a.set && b.set)
            ...
        ---

        Argument parameters are assigned to the last known target, such
        that multiple parameters accumulate:
        ---
        args.parse ("-a=1 -a=2 foo", true);
        assert (args('a').assigned.length is 3);
        ---

        That example results in argument 'a' assigned three parameters. 
        Note '=', ' ' and ':' are equivalent argument separators. Those
        parameters without a prior argument are assigned to the default
        argument, where null specifies the default argument:
        ---
        args.parse ("one two");
        assert (args(null).assigned.length is 2);
        ---
        
        Examples thus far have used 'sloppy' argument declaration, via
        the second argument of parse() being set true. This allows the
        parser to create argument declaration on-the-fly, which can be
        handy for trivial usage. However, most features require the a-
        priori declaration of arguments:
        ---
        args = new Arguments;
        args('x').required;
        if (! args.parse("-x"))
              // x not supplied!
        ---

        Sloppy arguments are disabled in that example, and a required
        argument 'x' is declared. The parse() method will fail if the
        pre-conditions are not fully met. Additional qualifiers include
        specifying how many parameters are allowed for each individual
        argument, default parameters, whether an argument requires the 
        presence or exclusion of another, etc. Qualifiers are typically 
        chained together and the following example shows argument "foo"
        being made required, with one parameter, aliased to 'f', and
        dependent upon the presence of another argument "bar":
        ---
        args("foo").required.params(1).aliased('f').requires("bar");
        ---

        A variety of known arguments can be declared in this manner
        and the parser will return true only where all conditions are
        met. Where a error condition occurs you may traverse the set
        of arguments to find out which argument has what error. This
        is handled as shown, where arg.error holds a defined code:
        ---
        if (! args.parse (...))
              foreach (arg; args)
                       if (arg.error)
                           ...
        ---
       
        Error codes are as follows:
        ---
        None:           ok (zero)
        ParamLo:        too few params for an argument
        ParamHi:        too many params for an argument
        Required:       missing argument is required 
        Requires:       depends on a missing argument
        Conflict:       conflicting argument is present
        Extra:          unexpected argument (see sloppy)
        ---
        
        A simpler way to handle errors is to invoke an internal format
        routine, which constructs error messages on your behalf:
        ---
        if (! args.parse (...))
              Stderr (args.errors(&Stderr.layout.sprint));
        ---

        Note that messages are constructed via a layout handler and
        the messages themselves may be customized (for i18n purposes).
        See the two errors() methods for more information on this.

        You may change the argument indicator(s) to be something other
        than "-" and "--" via the constructor. You might, for example, 
        need to specify a "/" indicator instead. See the unit-test code 
        for an example of this plus a variety of other options.

*******************************************************************************/

class Arguments
{
        public alias get                opCall;         // args("name")
        public alias get                opIndex;        // args["name"]

        private Argument[char[]]        args;           // the set of args
        private Argument[char[]]        aliases;        // set of aliases
        private char[]                  sp = "-",       // short prefix
                                        lp = "--";      // long prefix
        private char[][]                msgs = errmsg;  // error messages

        private const char[][] errmsg =                 // default errors
                [
                "argument '{0}' expects {2} parameter(s) but has {1}\n", 
                "argument '{0}' expects {3} parameter(s) but has {1}\n", 
                "argument '{0}' is missing\n", 
                "argument '{0}' requires '{4}'\n", 
                "argument '{0}' conflicts with '{4}'\n", 
                "unexpected argument '{0}'\n", 
                ];

        /***********************************************************************
              
              Construct with the specific short & long prefixes

        ***********************************************************************/
        
        this (char[] sp="-", char[] lp="--")
        {
                this.sp = sp;
                this.lp = lp;
                get(null).params;
        }

        /***********************************************************************
              
                Parse a string into a set of Argument instances. The 'sloppy'
                option allows for unexpected arguments without error.
                
                Returns false where an error condition occurred, whereupon the 
                arguments should be traversed to discover said condition(s):
                ---
                auto args = new Arguments;
                if (! args.parse (...))
                      Stderr (args.errors(&Stderr.layout.sprint));
                ---

        ***********************************************************************/
        
        final bool parse (char[] input, bool sloppy=false)
        {
                auto current = get(null);
                foreach (s; quotes(input, " :="))
                         if (s.length)
                            {
                            debug Stdout.formatln ("'{}'", s);
                            if (s.length >= lp.length && s[0..lp.length] == lp)
                                current = enable (s[lp.length..$], sloppy);
                            else
                               if (s.length >= sp.length && s[0..sp.length] == sp)
                                   current = enable (s[sp.length..$], sloppy, true);
                               else
                                  current.append (s);
                            }  
                int error;
                foreach (arg; args)
                         error |= arg.valid;
                return error is 0;
        }

        /***********************************************************************
              
                Parse string[] into a set of Argument instances. The 'sloppy'
                option allows for unexpected arguments without error.
                
                Returns false where an error condition occurred, whereupon the 
                arguments should be traversed to discover said condition(s):
                ---
                auto args = new Arguments;
                if (! args.parse (...))
                      Stderr (args.errors(&Stderr.layout.sprint));
                ---

        ***********************************************************************/
        
        final bool parse (char[][] input, bool sloppy=false)
        {
                char[1024] tmp = void;
                return parse (join(input, " ", tmp), sloppy);
        }

        /***********************************************************************
              
                Clear parameter assignments, flags and errors. Note this 
                does not remove any Arguments

        ***********************************************************************/
        
        final Arguments clear ()
        {
                foreach (arg; args)
                        {
                        arg.set = false;
                        arg.error = arg.None;
                        arg.values = null;
                        }
                return this;
        }

        /***********************************************************************
              
                Obtain an argument reference, creating an new instance where
                necessary. Use array indexing or opCall syntax if you prefer

        ***********************************************************************/
        
        final Argument get (char name)
        {
                return get ((&name)[0..1]);
        }

        /***********************************************************************
              
                Obtain an argument reference, creating an new instance where
                necessary. Use array indexing or opCall syntax if you prefer

        ***********************************************************************/
        
        final Argument get (char[] name)
        {
                auto a = name in args;
                if (a is null)
                    return name=name.dup, args[name] = new Argument(name);
                return *a;
        }

        /***********************************************************************

                Traverse the set of arguments

        ***********************************************************************/

        final int opApply (int delegate(ref Argument) dg)
        {
                int result;
                foreach (arg; args)  
                         if ((result=dg(arg)) != 0)
                              break;
                return result;
        }

        /***********************************************************************

                Construct a string of error messages, using the given
                delegate to format the output. You would typically pass
                the system formatter here, like so:
                ---
                auto msgs = args.errors (&Stderr.layout.sprint);
                ---

                The messages are replacable with custom version (i18n)
                instead, using the errors(char[][]) method

        ***********************************************************************/

        char[] errors (char[] delegate(char[] buf, char[] fmt, ...) dg)
        {
                char[256] tmp;
                char[] result;
                foreach (arg; args)
                         if (arg.error)
                             result ~= dg (tmp, msgs[arg.error-1], arg.name, 
                                           arg.values.length, arg.min, arg.max, 
                                           arg.bogus);
                return result;                             
        }

        /***********************************************************************
                
                Use this method to replace the default error messages. Note
                that arguments are passed to the formatter in the following
                order, and these should be indexed appropriately by each of
                the error messages (see examples in errmsg above):
                ---
                index 0: the argument name
                index 1: number of parameters
                index 2: configured minimum parameters
                index 3: configured maximum parameters
                index 4: conflicting/dependent argument name
                ---

        ***********************************************************************/

        Arguments errors (char[][] errors)
        {
                if (errors.length is errmsg.length)
                    msgs = errors;
                return this;
        }

        /***********************************************************************
              
                Indicate the existance of an argument, and handle sloppy
                options along with multiple-flags and smushed parameters.
                Note that sloppy arguments are configured with parameters
                enabled.

        ***********************************************************************/
        
        private Argument enable (char[] elem, bool sloppy, bool flag=false)
        {
                if (flag && elem.length > 1)
                   {
                   // locate arg for first char
                   auto arg = enable (elem[0..1], sloppy);
                   elem = elem[1..$];

                   // smush the remaining text, or treat then as more args
                   if (arg.cat)
                       arg.append (elem);
                   else
                      foreach (c; elem)
                               arg = enable ((&c)[0..1], sloppy);
                   return arg;
                   }

                // if not in args, or in aliases, then create new arg
                auto a = elem in args;
                if (a is null)
                    if ((a = elem in aliases) is null)
                         return get(elem).params.enable(!sloppy);
                return a.enable;
        }

        /***********************************************************************
              
                A specific argument instance. You get one of these from 
                Arguments.get() and visit them via Arguments.opApply()

        ***********************************************************************/
        
        class Argument
        {       
                /***************************************************************
                
                        Error identifiers:
                        ---
                        None:           ok
                        ParamLo:        too few params for an argument
                        ParamHi:        too many params for an argument
                        Required:       missing argument is required 
                        Requires:       depends on a missing argument
                        Conflict:       conflicting argument is present
                        Extra:          unexpected argument (see sloppy)
                        ---

                ***************************************************************/
        
                enum {None, ParamLo, ParamHi, Required, Requires, Conflict, Extra};

                alias void delegate() Invoker;
                alias void delegate(char[] value) Validator;

                int             min,            // minimum params
                                max,            // maximum params
                                error;          // error condition
                bool            set,            // arg is present
                                req,            // arg is required
                                cat;            // arg is smushable
                char[]          name,           // arg name
                                text,           // help text
                                bogus;          // name of conflict
                char[][]        values,         // assigned values
                                deefalts;       // assigned defaults
                Invoker         invoker;        // invocation callback
                Validator       validator;      // validation callback
                Argument[]      dependees,      // who we require
                                conflictees;    // who we conflict with
                
                /***************************************************************
              
                        Create with the given name

                ***************************************************************/
        
                this (char[] name)
                {
                        this.name = name;
                }

                /***************************************************************
              
                        Return the name of this argument

                ***************************************************************/
        
                override char[] toString()
                {
                        return name;
                }

                /***************************************************************
              
                        Alias this argument with the given name. If you need 
                        long-names to be aliased, create the long-name first
                        and alias it to a short one

                ***************************************************************/
        
                final Argument aliased (char name)
                {
                        this.outer.aliases[(&name)[0..1].dup] = this;
                        return this;
                }

                /***************************************************************
              
                        Make this argument a requirement

                ***************************************************************/
        
                final Argument required ()
                {
                        this.req = true;
                        return this;
                }

                /***************************************************************
              
                        Set this argument to depend upon another

                ***************************************************************/
        
                final Argument requires (Argument arg)
                {
                        dependees ~= arg;
                        return this;
                }

                /***************************************************************
              
                        Set this argument to depend upon another

                ***************************************************************/
        
                final Argument requires (char[] other)
                {
                        return requires (this.outer.get(other));
                }

                /***************************************************************
              
                        Set this argument to depend upon another

                ***************************************************************/
        
                final Argument requires (char other)
                {
                        return requires ((&other)[0..1]);
                }

                /***************************************************************
              
                        Set this argument to conflict with another

                ***************************************************************/
        
                final Argument conflicts (Argument arg)
                {
                        conflictees ~= arg;
                        return this;
                }

                /***************************************************************
              
                        Set this argument to conflict with another

                ***************************************************************/
        
                final Argument conflicts (char[] other)
                {
                        return conflicts (this.outer.get(other));
                }

                /***************************************************************
              
                        Set this argument to conflict with another

                ***************************************************************/
        
                final Argument conflicts (char other)
                {
                        return conflicts ((&other)[0..1]);
                }

                /***************************************************************
              
                        Enable parameter assignment: 0 to 100 by default

                ***************************************************************/
        
                final Argument params ()
                {
                        return params (0, 100);
                }

                /***************************************************************
              
                        Set an exact number of parameters required

                ***************************************************************/
        
                final Argument params (int count)
                {
                        return params (count, count);
                }

                /***************************************************************
              
                        Set both the minimum and maximum parameter counts

                ***************************************************************/
        
                final Argument params (int min, int max)
                {
                        this.min = min;
                        this.max = max;
                        return this;
                }

                /***************************************************************
                        
                        Add another default parameter for this argument

                ***************************************************************/
        
                final Argument defaults (char[] values)
                {
                        this.deefalts ~= values;
                        return this;
                }

                /***************************************************************
              
                        Set a validator for this argument, fired when a
                        parameter is appended to an argument

                ***************************************************************/
        
                final Argument bind (Validator validator)
                {
                        this.validator = validator;
                        return this;
                }

                /***************************************************************
              
                        Set an invoker for this argument, fired when an
                        argument declaration is seen

                ***************************************************************/
        
                final Argument bind (Invoker invoker)
                {
                        this.invoker = invoker;
                        return this;
                }

                /***************************************************************
              
                        Enable smushing for this argument, where "-ofile" 
                        would result in "file" being assigned to argument 
                        'o'

                ***************************************************************/
        
                final Argument smush ()
                {
                        cat = true;
                        return this;
                }

                /***************************************************************
                
                        Set the help text

                ***************************************************************/
        
                final Argument help (char[] text)
                {
                        this.text = text;
                        return this;
                }

                /***************************************************************
                
                        return the assigned parameters, or the defaults if
                        no parameters were assigned

                ***************************************************************/
        
                final char[][] assigned ()
                {
                        return values.length ? values : deefalts;
                }

                /***************************************************************
              
                        This arg is present, but set an error condition
                        (Extra) when unexpected and sloppy is not enabled.
                        Fires any configured invoker callback.

                ***************************************************************/
        
                private Argument enable (bool unexpected=false)
                {
                        this.set = true;
                        if (invoker)
                            invoker();
                        if (unexpected)
                            error = Extra;
                        return this;
                }

                /***************************************************************
              
                        Append a parameter value, involing validator as
                        necessary

                ***************************************************************/
        
                private Argument append (char[] value)
                {       
                        if (validator)
                            validator(value);
                        values ~= value;
                        return this;
                }

                /***************************************************************
                
                        Test and set the error flag appropriately 

                ***************************************************************/
        
                private int valid ()
                {
                        if (error is None)
                            if (req && !set)      
                                error = Required;
                            else
                               if (set)
                                  {
                                  if (values.length < min)
                                      error = ParamLo;
                                  else
                                     if (values.length > max)
                                         error = ParamHi;
                                     else
                                        {
                                        foreach (arg; dependees)
                                                 if (! arg.set)
                                                       error = Requires, bogus=arg.name;

                                        foreach (arg; conflictees)
                                                 if (arg.set)
                                                     error = Conflict, bogus=arg.name;
                                        }
                                  }

                        debug Stdout.formatln ("{}: error={}, set={}, min={}, max={}, "
                                               "req={}, values={}, defaults={}, requires={}", 
                                               name, error, set, min, max, req, values, 
                                               deefalts, dependees);
                        return error;
                }
        }
}


/*******************************************************************************
      
*******************************************************************************/

debug(UnitTest)
{
        unittest
        {
        auto args = new Arguments;

        // basic 
        auto x = args['x'];
        assert (args.parse (""));
        x.required;
        assert (args.parse ("") is false);
        assert (args.clear.parse ("-x"));
        assert (x.set);

        // alias
        x.aliased('X');
        assert (args.clear.parse ("-X"));
        assert (x.set);

        // unexpected arg (with sloppy)
        assert (args.clear.parse ("-y") is false);
        assert (args.clear.parse ("-y") is false);
        assert (args.clear.parse ("-y", true) is false);
        assert (args['y'].set);
        assert (args.clear.parse ("-x -y", true));

        // parameters
        assert (args.clear.parse ("-x param") is false);
        x.params(1);
        assert (args.clear.parse ("-x=param"));
        assert (x.assigned.length is 1);
        assert (args.clear.parse ("-x:param"));
        assert (x.assigned.length is 1);
        assert (args.clear.parse ("-x param"));
        assert (x.assigned.length is 1);
        assert (args.clear.parse ("-x = param"));
        assert (x.assigned.length is 1);
        assert (args.clear.parse ("-x :param"));
        assert (x.assigned.length is 1);
        assert (x.assigned[0] == "param");

        // too many args
        assert (args.clear.parse ("-x param1 param2") is false);

        // now with default params
        assert (args.clear.parse ("param1 param2 -x:blah"));
        assert (args[null].assigned.length is 2);
        assert (args(null).assigned.length is 2);
        assert (x.assigned.length is 1);
        x.params(0);
        assert (args.clear.parse ("-x:blah") is false);

        // multiple flags, with alias and sloppy
        assert (args.clear.parse ("-xy"));
        assert (args.clear.parse ("-xyX"));
        assert (x.set);
        assert (args['y'].set);
        assert (args.clear.parse ("-xyz") is false);
        assert (args.clear.parse ("-xyz", true));
        auto z = args['z'];
        assert (z.set);

        // multiple flags with trailing arg
        assert (args.clear.parse ("-xyz=10"));
        assert (z.assigned.length is 1);

        // again, but without sloppy param declaration
        z.params(0);
        assert (args.clear.parse ("-xyz=10") is false);

        // x requires y
        x.requires('y');
        assert (args.clear.parse ("-xy"));
        assert (args.clear.parse ("-xz") is false);

        // defaults
        z.defaults("foo");
        assert (args.clear.parse ("-xy"));
        assert (z.assigned.length is 1);

        // long names, with params
        assert (args.clear.parse ("-xy --foobar") is false);
        assert (args.clear.parse ("-xy --foobar", true));
        assert (args["y"].set && x.set);
        assert (args["foobar"].set);
        assert (args.clear.parse ("-xy --foobar=10"));
        assert (args["foobar"].assigned.length is 1);
        assert (args["foobar"].assigned[0] == "10");

        // smush argument z, but not others
        z.params;
        assert (args.clear.parse ("-xy -zsmush") is false);
        assert (x.set);
        z.smush;
        assert (args.clear.parse ("-xy -zsmush"));
        assert (z.assigned.length is 1);
        assert (z.assigned[0] == "smush");
        assert (x.assigned.length is 0);
        z.params(0);

        // conflict x with z
        x.conflicts(z);
        assert (args.clear.parse ("-xyz") is false);

        // word mode, with prefix elimination
        args = new Arguments (null, null);
        assert (args.clear.parse ("foo bar wumpus") is false);
        assert (args.clear.parse ("foo bar wumpus wombat", true));
        assert (args("foo").set);
        assert (args("bar").set);
        assert (args("wumpus").set);
        assert (args("wombat").set);

        // use '/' instead of '-'
        args = new Arguments ("/", "/");
        assert (args.clear.parse ("/foo /bar /wumpus") is false);
        assert (args.clear.parse ("/foo /bar /wumpus /wombat", true));
        assert (args("foo").set);
        assert (args("bar").set);
        assert (args("wumpus").set);
        assert (args("wombat").set);

        // use '/' for short and '-' for long
        args = new Arguments ("/", "-");
        assert (args.clear.parse ("-foo -bar -wumpus -wombat /abc", true));
        assert (args("foo").set);
        assert (args("bar").set);
        assert (args("wumpus").set);
        assert (args("wombat").set);
        assert (args("a").set);
        assert (args("b").set);
        assert (args("c").set);
        }
}

/*******************************************************************************
      
*******************************************************************************/

debug (Arguments)
{       
        import tango.io.Stdout;

        void main()
        {
                auto args = new Arguments;

                args('x').aliased('X').params.required;
                args('y').defaults("hi").params(3).conflicts('a');
                args('a').required.defaults("hi").requires('x').requires("foo").params;
                if (! args.parse ("one two -a=bar -y=ff -y:ss --foobar:blah --foobar barf blah", true))
                      Stdout (args.errors(&Stdout.layout.sprint));
        }
}