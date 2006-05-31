/*
 * Placed into the Public Domain.
 * written by Walter Bright
 * www.digitalmars.com
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 */

private
{
    import std.c.stdlib;
    import std.c.string;
    import std.c.stdio;
}

extern (C) void _STI_monitor_staticctor();
extern (C) void _STD_monitor_staticdtor();
extern (C) void _STI_critical_init();
extern (C) void _STD_critical_term();
extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();
extern (C) void _moduleDtor();
extern (C) void _moduleUnitTests();

/***********************************
 * These functions must be defined for any D program linked
 * against this library.
 */
extern (C) void onAssertError( char[] file, uint line );
extern (C) void onArrayBoundsError( char[] file, uint line );
extern (C) void onSwitchError( char[] file, uint line );
// this function is called from the utf module
//extern (C) void onUnicodeError( char[] msg, size_t idx );

/***********************************
 * These are internal callbacks for various language errors.
 */
extern (C) void _d_assert( char[] file, uint line )
{
    onAssertError( file, line );
}

extern (C) void _d_array_bounds( char[] file, uint line )
{
    onArrayBoundsError( file, line );
}

extern (C) void _d_switch_error( char[] file, uint line )
{
    onSwitchError( file, line );
}

extern (C) bool no_catch_exceptions = false;

/***********************************
 * The D main() function supplied by the user's program
 */
int main(char[][] args);

/***********************************
 * Substitutes for the C main() function.
 * It's purpose is to wrap the call to the D main()
 * function and catch any unhandled exceptions.
 */
//extern (C) int wmain( int argc, wchar_t** argv )
extern (C) int main(int argc, char **argv)
{
    char[] *am;
    char[][] args;
    int i;
    int result;
    int myesp;
    int myebx;

    version (linux)
    {
	    _STI_monitor_staticctor();
	    _STI_critical_init();
	    gc_init();
	    am = cast(char[]*) malloc(argc * (char[]).sizeof);
	    // BUG: alloca() conflicts with try-catch-finally stack unwinding
	    //am = (char[] *) alloca(argc * (char[]).sizeof);
    }
    else version (Win32)
    {
	    gc_init();
	    _minit();
	    am = cast(char[]*) alloca(argc * (char[]).sizeof);
    }
    else
    {
        static assert( false );
    }

    if (no_catch_exceptions)
    {
    	_moduleCtor();
    	_moduleUnitTests();

    	for (i = 0; i < argc; i++)
    	{
    	    int len = strlen(argv[i]);
    	    am[i] = argv[i][0 .. len];
    	}

    	args = am[0 .. argc];

    	result = main(args);
    	_moduleDtor();
    	gc_term();
    }
    else
    {
        try
        {
    	    _moduleCtor();
    	    _moduleUnitTests();
        	for (i = 0; i < argc; i++)
        	{
        	    int len = strlen(argv[i]);
        	    am[i] = argv[i][0 .. len];
        	}

        	args = am[0 .. argc];

        	result = main(args);
    	    _moduleDtor();
    	    gc_term();
        }
        catch (Exception e)
        {
            while (e)
            {
                if (e.file)
        	        fprintf(stderr, "%.*s(%u): %.*s\n", e.file, e.line, e.msg);
        	    else
        	        fprintf(stderr, "%.*s\n", e.toString());
        	    e = e.next;
        	}
    	    exit(EXIT_FAILURE);
        }
        catch (Object o)
        {
    	    fprintf(stderr, "%.*s\n", o.toString());
    	    exit(EXIT_FAILURE);
        }
    }

    version (linux)
    {
	    free(am);
	    _STD_critical_term();
	    _STD_monitor_staticdtor();
    }
    return result;
}