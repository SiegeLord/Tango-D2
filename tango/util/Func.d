/**
 * Contains functions that operate on functions and delegates.
 *
 * Copyright:   Copyright &copy; 2009, Daniel Keep.
 * License:     BSD style: $(LICENSE)
 * Authors:     Daniel Keep
 */
module tango.util.Func;

import tango.core.Traits;

/*
 * This *should* be simple, but obviously isn't.  The problem is that
 * you can't have storage classes in a tuple, meaning that you cannot
 * directly infer or manipulate the argument list.
 *
 * To do this, we have to actually *parse* the result of
 * ParameterTupleOf!(Fn).stringof (which actually includes both the types and
 * storage classes of each argument).
 */

/*
 * This template rewrites a function type to the corresponding delegate type.
 */
private template ToDgType(Fn)
{
    mixin("alias ReturnTypeOf!(Fn) delegate"~ParameterTupleOf!(Fn).stringof
        ~" ToDgType;");
}

debug( UnitTest )
{
    static assert( is( 
        ToDgType!(long function(byte, ref short, out int))
        == long delegate(byte, ref short, out int) ) );
}

/*
 * Provides a CTFE-compatible toString(int).
 */
private char[] toString_ct(int v)
{
    if( v == 0 )
        return "0";

    if( v < 0 )
        return "-" ~ toString_ct(-v);

    char[] r;
    while( v > 0 )
    {
        r = "0123456789"[v%10] ~ r;
        v /= 10;
    }

    return r;
}

debug( UnitTest )
{
    static assert( toString_ct(0) == "0" );
    static assert( toString_ct(1) == "1" );
    static assert( toString_ct(9) == "9" );
    static assert( toString_ct(10) == "10" );
    static assert( toString_ct(19) == "19" );
    static assert( toString_ct(-1) == "-1" );
    static assert( toString_ct(-9) == "-9" );
    static assert( toString_ct(-10) == "-10" );
}

/*
 * Converts an argument list (sans argument identifiers) into an argument list
 * with identifiers; arguments are named a0, a1, a2 and so on.
 */
private char[] toArgList_ct(char[] args)
{
    // Strip off parens
    if( args[0] == '(' && args[$-1] == ')' )
        return "("~toArgList_ct(args[1..$-1])~")";
    
    // The no-argument case is easy :D
    if( args == "" )
        return "";
    
    // We need to translate the type list into an argument list.  To do this,
    // we will scan the string for commas.  If we see an
    // opening paren, we will ignore any commas until we find the matching
    // closing paren.
    //
    // When we find a comma, we'll insert "an" before it,
    // where n is the index of the argument.
    //
    // The reason we can't use tuples is that tuples can't have ref, out,
    // scope, etc. in the type list.
    //
    // Lastly, when we run out of string to process, we append the last
    // argument name.

    int depth = 0; // how deep in parens we are
    int argord = 0; // argument ordinal
    char[] result;

    foreach( c ; args )
    {
        if( depth == 0 )
        {
            if( c == '(' )
                ++ depth;

            else if( c == ',' )
            {
                result ~= " a"~toString_ct(argord);
                ++ argord;
            }
        }
        else
        {
            if( c == '(' )
                ++ depth;
            else if( c == ')' )
                -- depth;
        }

        result ~= c;
    }
    
    return result~" a"~toString_ct(argord);
}

debug( UnitTest )
{
    static assert( toArgList_ct("(byte, ref short, out int, scope float)")
            == "(byte a0, ref short a1, out int a2, scope float a3)" );
}

/*
 * Given a function type, resolves to a named argument list.
 */
private template ToArgList(Fn)
{
    const ToArgList = toArgList_ct(ParameterTupleOf!(Fn).stringof);
}

/*
 * Generates an argument list with JUST the names; as suitable for, say,
 * calling a function.
 */
private char[] toArgNameList_ct(int args)
{
    char[] result;

    for( int i=0; i<args; ++i )
    {
        if( i > 0 ) result ~= ", ";
        result ~= "a" ~ toString_ct(i);
    }

    return "(" ~ result ~ ")";
}

debug( UnitTest )
{
    static assert( toArgNameList_ct(0) == "()" );
    static assert( toArgNameList_ct(1) == "(a0)" );
    static assert( toArgNameList_ct(2) == "(a0, a1)" );
}

/*
 * Given a function type, resolves to a list of argument names.
 */
private template ToArgNameList(Fn)
{
    const ToArgNameList = toArgNameList_ct(ParameterTupleOf!(Fn).length);
}

/*
 * This is the struct which wraps the call to the function pointer.
 *
 * In debug builds, this is a pretty standard heap-allocated instance that you
 * take a delegate to.  In release builds, we use a trick that allows us to
 * get away with NOT heap-allocating the stack: we hide the function pointer
 * in the delegate's this pointer.
 */
private struct WrapFn(Fn)
{
    debug
    {
        Fn ptr;

        private const impl = `
            ` ~ ReturnTypeOf!(Fn).stringof ~ ` call` ~ ToArgList!(Fn) ~ `
            {
                return ptr` ~ ToArgNameList!(Fn) ~ `;
            }
        `;
    }
    else
    {
        private const impl = `
            ` ~ ReturnTypeOf!(Fn).stringof ~ ` call` ~ ToArgList!(Fn) ~ `
            {
                return (cast(Fn)this)` ~ ToArgNameList!(Fn) ~ `;
            }
        `;
    }

    //debug(todg) pragma(msg, impl);
    mixin(impl);
}

/**
 * Converts a function pointer into a delegate of the corresponding type.
 * This delegate merely forwards calls to the given function pointer.
 *
 * For release builds, this is done without requiring any heap allocations.
 * Debug builds use a heap-based method to improve compatibility with
 * debuggers.
 */
ToDgType!(Fn) toDg(Fn)(Fn fn)
{
    debug
    {
        auto wrap = new WrapFn!(Fn);
        wrap.ptr = fn;
        return &wrap.call;
    }
    else
    {
        ToDgType!(Fn) dg;
        WrapFn!(Fn) wrap;
    
        dg.ptr = fn;
        dg.funcptr = cast(Fn)(&wrap.call);

        return dg;
    }
}

debug( UnitTest ):
private:

char[]  foo_a;
int     foo_b;
float   foo_c;

int foo(char[] a, out int b, ref float c)
{
    foo_a = a;
    foo_b = b;
    foo_c = c;

    b = 1701;
    c = cast(float) 3.141;
    return 42;
}

import tango.util.Convert;

unittest
{
    void bar(int delegate(char[], out int, ref float) dg)
    {
        char[] a = "hello";
        int b = 7;
        float c = 2.159;
        
        int r = dg(a, b, c);

        assert( r == 42 );
        assert( b == 1701 );
        assert( c == cast(float) 3.141 );

        assert( foo_a == "hello" );
        assert( foo_b == 0 );
        assert( foo_c == cast(float) 2.159 );
    }

    bar(toDg(&foo));
}

