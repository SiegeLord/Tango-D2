
/* NOTE: This file is based on dmain2.d from the original DMD distribution.

*/

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */
module rt.compiler.gdc.rt.dgccmain2;
private
{
    import rt.compiler.gdc.rt.memory;
    import rt.compiler.util.console;

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
extern (C) void thread_joinAll();

version (GNU_CBridge_Stdio)
{
    extern (C) void _d_gnu_cbridge_init_stdio();
}

/***********************************
 * These functions must be defined for any D program linked
 * against this library.
 */
extern (C) void onAssertError( char[] file, size_t line );
extern (C) void onAssertErrorMsg( char[] file, size_t line, char[] msg );
extern (C) void onArrayBoundsError( char[] file, size_t line );
extern (C) void onSwitchError( char[] file, size_t line );
extern (C) bool runModuleUnitTests();

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

bool _d_isHalting = false;

extern (C) bool rt_isHalting()
{
    return _d_isHalting;
}

extern (C) bool rt_trapExceptions = true;

void _d_criticalInit()
{
    version (GC_Use_Stack_Guess)
    {
        int dummy;
        stackOriginGuess = &dummy;
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
    }
}

alias void delegate( Exception ) ExceptionHandler;

extern (C) bool rt_init( ExceptionHandler dg = null )
{
    _d_criticalInit();

    try
    {
        gc_init();
        _moduleCtor();
        return true;
    }
    catch( Exception e )
    {
        if( dg ){
            dg( e );
        } else {
            console("exception while executing module initializers:\n");
            e.writeOut(delegate void(char[]s){
                console(s);
            });
            console();
        }
    }
    catch
    {
        console("error while executing module initializers\n");
    }
    _d_criticalTerm();
    return false;
}

void _d_criticalTerm()
{
    version (all)
    {
        _STD_critical_term();
        _STD_monitor_staticdtor();
    }
}

extern (C) bool rt_term( ExceptionHandler dg = null )
{
    try
    {
        thread_joinAll();
        _d_isHalting = true;
        _moduleDtor();
        gc_term();
        return true;
    }
    catch( Exception e )
    {
        if( dg )
            dg( e );
    }
    catch
    {

    }
    finally
    {
        _d_criticalTerm();
    }
    return false;
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
    }

    version (all)
    {
        char[]* am = cast(char[]*) malloc(argc * (char[]).sizeof);
        scope(exit) free(am);

        for (size_t i = 0; i < argc; i++)
        {
            auto len = strlen(argv[i]);
            am[i] = argv[i][0 .. len];
        }
        args = am[0 .. argc];
    }

    bool trapExceptions = rt_trapExceptions;

    void tryExec(void delegate() dg)
    {

        if (trapExceptions)
        {
            try
            {
                dg();
            }
            catch (Exception e)
            {
                e.writeOut(delegate void(char[] s){ console(s); });
                result = EXIT_FAILURE;
            }
            catch (Object o)
            {
                // fprintf(stderr, "%.*s\n", o.toString());
                console (o.toString)("\n");
                result = EXIT_FAILURE;
            }
        }
        else
        {
            dg();
        }
    }

    // NOTE: The lifetime of a process is much like the lifetime of an object:
    //       it is initialized, then used, then destroyed.  If initialization
    //       fails, the successive two steps are never reached.  However, if
    //       initialization succeeds, then cleanup will occur even if the use
    //       step fails in some way.  Here, the use phase consists of running
    //       the user's main function.  If main terminates with an exception,
    //       the exception is handled and then cleanup begins.  An exception
    //       thrown during cleanup, however, will abort the cleanup process.

    void runMain()
    {
        result = main_func(args);
    }

    void runAll()
    {
        gc_init();
        _moduleCtor();
        if (runModuleUnitTests())
            tryExec(&runMain);
        _d_isHalting = true;
        thread_joinAll();
        _moduleDtor();
        gc_term();
    }

    tryExec(&runAll);

    version (all)
    {
        _STD_critical_term();
        _STD_monitor_staticdtor();
    }
    return result;
}
