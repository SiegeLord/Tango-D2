
/* NOTE: This file is based on dmain2.d from the original DMD distribution.

*/

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */

private
{
    import memory;
    import util.console;

    import tango.stdc.stddef;
    import tango.stdc.stdlib;
    import tango.stdc.string;
}

version( Win32 )
{
    extern (Windows) void*      LocalFree(void*);
    extern (Windows) wchar_t*   GetCommandLineW();
    extern (Windows) wchar_t**  CommandLineToArgvW(wchar_t*, int*);
    extern (Windows) export int WideCharToMultiByte(uint, uint, wchar_t*, int, char*, int, char*, int);
    pragma(lib, "shell32.lib"); // needed for CommandLineToArgvW
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
extern (C) void onAssertError( char[] file, size_t line );
extern (C) void onAssertErrorMsg( char[] file, size_t line, char[] msg );
extern (C) void onArrayBoundsError( char[] file, size_t line );
extern (C) void onSwitchError( char[] file, size_t line );
// this function is called from the utf module
//extern (C) void onUnicodeError( char[] msg, size_t idx );

/***********************************
 * These are internal callbacks for various language errors.
 */
extern (C) void _d_assert( char[] file, uint line )
{
    onAssertError( file, line );
}

extern (C) static void _d_assert_msg( char[] msg, char[] file, uint line )
{
    onAssertErrorMsg( file, line, msg );
}

extern (C) void _d_array_bounds( char[] file, uint line )
{
    onArrayBoundsError( file, line );
}

extern (C) void _d_switch_error( char[] file, uint line )
{
    onSwitchError( file, line );
}

bool isHalting = false;

extern (C) bool cr_isHalting()
{
    return isHalting;
}

/***********************************
 * The D main() function supplied by the user's program
 */
//int main(char[][] args);
extern (C) alias int function(char[][] args) main_type;

/***********************************
 * Substitutes for the C main() function.
 * It's purpose is to wrap the call to the D main()
 * function and catch any unhandled exceptions.
 */

/* Note that this is not the C main function, nor does it refer
   to the D main function as in the DMD version.  The actual C
   main is in cmain.d

   This serves two purposes:
   1) Special applications that have a C main declared elsewhere.

   2) It is possible to create D shared libraries that can be used
   by non-D executables. (TODO: Not complete, need a general library
   init routine.)
*/

extern (C) int _d_run_main(int argc, char **argv, main_type main_func)
{
    char[][] args;
    int result;

    version (GC_Use_Stack_Guess)
    {
        stackOriginGuess = &argv;
    }
    version (GNU_CBridge_Stdio)
    {
        _d_gnu_cbridge_init_stdio();
    }
    version (all)
    {
        _STI_monitor_staticctor();
        _STI_critical_init();
        initStaticDataPtrs();
        gc_init();
    }

    version (all)
    {
        char[]* am = cast(char[]*) malloc(argc * (char[]).sizeof);
        scope(exit) free(am);

        for (int i = 0; i < argc; i++)
        {
            int len = strlen(argv[i]);
            am[i] = argv[i][0 .. len];
        }
        args = am[0 .. argc];
    }

    try
    {
        _moduleCtor();
        _moduleUnitTests();
        result = main_func(args);
        isHalting = true;
        _moduleDtor();
        gc_term();
    }
    catch (Exception e)
    {
        while (e)
        {
            if (e.file)
            {
               fprintf(stderr, "%.*s(%u): %.*s\n", e.file, e.line, e.msg);
               //console (e.file)("(")(e.line)("): ")(e.msg)("\n");
            }
            else
            {
               fprintf(stderr, "%.*s\n", e.toUtf8());
               //console (e.toUtf8)("\n");
            }
            e = e.next;
        }
        exit(EXIT_FAILURE);
    }
    catch (Object o)
    {
        fprintf(stderr, "%.*s\n", o.toUtf8());
        //console (o.toUtf8)("\n");
        exit(EXIT_FAILURE);
    }

    version (all)
    {
        _STD_critical_term();
        _STD_monitor_staticdtor();
    }
    return result;
}
