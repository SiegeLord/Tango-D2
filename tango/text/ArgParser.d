/*******************************************************************************

        copyright:      Copyright (c) 2005-2006 Lars Ivar Igesund, 
                        Eric Anderton. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005      
        
        author:         Lars Ivar Igesund, Eric Anderton

*******************************************************************************/

module tango.text.ArgParser;

/**
    An alias to a delegate taking a char[] as a parameter and returning
    an uint. The value parameter will hold any chars immediately
    following the argument. The returned value tell how many chars of 
    value was used by the callback.
*/
alias uint delegate (char[] value) ArgParserCallback;

/**
    An alias to a delegate taking a char[] as a parameter and returning
    an uint. The value parameter will hold any chars immediately
    following the argument. The returned value tell how many chars of 
    value was used by the callback.
    
    The ordinal argument represents which default argument this is for
    the given stream of arguments.  The first default argument will
    be ordinal=0 with each successive call to this callback having
    ordinal values of 1, 2, 3 and so forth.
*/
alias uint delegate (char[] value,uint ordinal) DefaultArgParserCallback;

/**
    An alias to a delegate taking no parameters and returning
    nothing.
*/
alias void delegate () ArgParserSimpleCallback;

/**
    A utility class to parse and handle your command line arguments.
*/
class ArgParser{
	/**
	    A helper struct containing a callback and an id to, corresponding to
	    the argId passed to one of the bind methods.
	*/
	protected struct PrefixCallback {
	    char[] id;
	    ArgParserCallback cb;
	}	

    protected PrefixCallback[][char[]] bindings;
    protected DefaultArgParserCallback[char[]] defaultBindings;
    protected uint[char[]] prefixOrdinals;
    protected char[][] prefixSearchOrder;
    protected DefaultArgParserCallback defaultbinding;
	private uint defaultOrdinal = 0;

    protected void addBinding(PrefixCallback pcb, char[] argPrefix){
        if (!(argPrefix in bindings)) {
            prefixSearchOrder ~= argPrefix;
        }
        bindings[argPrefix] ~= pcb;
    }

    /**
        Binds a delegate callback to argument with a prefix and 
        a argId.
        
        Params:
            argPrefix = the prefix of the argument, e.g. a dash '-'.
            argId = the name of the argument, what follows the prefix
            cb = the delegate that should be called when this argument is found
    */
    public void bind(char[] argPrefix, char[] argId, ArgParserCallback cb){
        PrefixCallback pcb;
        pcb.id = argId;
        pcb.cb = cb;
        addBinding(pcb, argPrefix);
    } 

    /**
        The constructor, creates an empty ArgParser instance.
    */
    public this(){
        defaultbinding = null;
    }
     
    /**
        The constructor, creates an ArgParser instance with a defined default callback.
    */    
    public this(DefaultArgParserCallback callback){
        defaultbinding = callback;
    }    

    protected class SimpleCallbackAdapter{
        ArgParserSimpleCallback callback;
        public this(ArgParserSimpleCallback callback){ 
            this.callback = callback; 
        }
        
        public uint adapterCallback(char[] value){
            callback();
            return value.length;
        }
    }

    /**
        Binds a delegate callback to argument with a prefix and 
        a argId.
        
        Params:
            argPrefix = the prefix of the argument, e.g. a dash '-'.
            argId = the name of the argument, what follows the prefix
            cb = the delegate that should be called when this argument is found
    */
    public void bind(char[] argPrefix, char[] argId, ArgParserSimpleCallback cb){
        SimpleCallbackAdapter adapter = new SimpleCallbackAdapter(cb);
        PrefixCallback pcb;
        pcb.id = argId;
        pcb.cb = &adapter.adapterCallback;
        addBinding(pcb, argPrefix);
    }
    
    /**
        Binds a delegate callback to all arguments with prefix argPrefix, but that
        do not conform to an argument bound in a call to bind(). 

        Params:
            argPrefix = the prefix for the callback
            callback = the default callback
    */
    public void bindDefault(char[] argPrefix, DefaultArgParserCallback callback){
        defaultBindings[argPrefix] = callback;
        prefixOrdinals[argPrefix] = 0;
        if (!(argPrefix in bindings)) {
            prefixSearchOrder ~= argPrefix;
        }
    }

    /**
        Binds a delegate callback to all arguments not conforming to an
        argument bound in a call to bind(). These arguments will be passed to the
        delegate without having any matching prefixes removed.

        Params:
            callback = the default callback
    */
    public void bindDefault(DefaultArgParserCallback callback){
        defaultbinding = callback;
    }

    /**
        Parses the arguments provided by the parameter. The bound
        callbacks are called as arguments are recognized.

        Params:
            arguments = the command line arguments from the application
    */
    public void parse(char[][] arguments){
        if (bindings.length == 0) return;

        foreach (char[] arg; arguments) {
            char[] argData = arg;
            while (argData.length > 0) {
                bool found = false;
                char[] argOrig = argData;
                foreach (char[] prefix; prefixSearchOrder) {
                    if(argData.length < prefix.length) continue; 
                    if(argData[0..prefix.length] != prefix) {
                        continue;
                    }
                    else {
                        argData = argData[prefix.length..$];
                    } 
                    if (prefix in bindings) {
                        foreach (PrefixCallback cb; bindings[prefix]) {
                            if (argData.length < cb.id.length) continue;
                            uint cbil = cb.id.length;
                            if (cb.id == argData[0..cbil]) {
                                found = true;
                                argData = argData[cbil..$];
                                uint consumed = cb.cb(argData);
                                argData = argData[consumed..$];
                                break;
                            }
                        }
                    }
                    if (found) {
                        break;
                    }
                    else if (prefix in defaultBindings){
                        uint consumed = defaultBindings[prefix](argData,prefixOrdinals[prefix]);
                        argData = argData[consumed..$];
                        prefixOrdinals[prefix]++;
                        found = true;
                        break;
                    }
                    argData = argOrig;
                }
                if (!found) {
                    if (!(defaultbinding is null)) {
                        uint consumed = defaultbinding(argData,defaultOrdinal);
                        argData = argData[consumed..$];
                        defaultOrdinal++;
                    }
                    else {
                        throw new Exception("Illegal argument "
                                  ~ argData);
                    }
                }
            }
        }
    }
}

unittest {

    //import mango.text.String;

    ArgParser parser = new ArgParser();
    bool h = h2 = b = bb = false;
    bool boolean = false;
    int n;

    parser.bind("--", "h2", delegate void(){
        h2 = true;
    });

    parser.bind("-", "h", delegate void(){
        h = true;
    });

    parser.bind("-", "bb", delegate void(){
        bb = true;
    });

    parser.bind("-", "b", delegate void(){
        b = true;
    });

    parser.bind("-", "n", delegate uint(char[] value){
        assert(value.length > 2);
        assert(value[1] == '=');
        n = toInt(value[2..5]);
        return 5;
    });

    parser.bind("-", "bool", delegate uint(char[] value){
        assert(value.length == 9);
        assert(value[4] == '=');
        if (value[5..9] == "true") {
            boolean = true;
        }
        else {
            assert(false);
        }
        return 9;
    });

    parser.bindDefault(delegate uint(char[] value, uint ordinal){
        assert (ordinal < 2);
        ordinalCount = ordinal;
        if (ordinal == 0) {
            assert(value == "ordinalTest1");
        }
        else if (ordinal == 1) {
            assert(value == "ordinalTest2");
        }
        return value.length;
    });

    parser.bindDefault("-", delegate uint(char[] value, uint ordinal){
        assert(ordinal < 2);
        dashOrdinalCount = ordinal;
        if (ordinal == 0) {
            assert(value == "dashTest1");
        }
        else if (ordinal == 1) {
            assert(value == "dashTest1");
        }
        return value.length;
    });

    parser.bindDefault("@", delegate uint(char[] value, uint ordinal){
        assert (value == "atTest");
        return value.length;
    });

    

}
