/*
 * Placed into the Public Domain.
 * written by Walter Bright
 * www.digitalmars.com
 */

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */
module rt.dmain2;

private
{
    import rt.compiler.util.console;
    import tango.stdc.stdlib : malloc, free, exit, EXIT_FAILURE;
    import tango.stdc.string : strlen;
    import tango.stdc.stdio : printf;
    import rt.memory;
}

version( Win32 )
{
    import tango.stdc.stdlib: wchar_t, alloca;
    import tango.stdc.string: wcslen;
    import tango.sys.win32.UserGdi: LocalFree,GetCommandLineW,CommandLineToArgvW,WideCharToMultiByte;
    //pragma(lib, "shell32.lib");   // needed for CommandLineToArgvW
    //pragma(lib, "tango-win32-dmd.lib"); // links Tango's Win32 library to reduce EXE size
}

extern (C) void _STI_monitor_staticctor();
extern (C) void _STD_monitor_staticdtor();
extern (C) void _STI_critical_init();
extern (C) void _STD_critical_term();
extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _moduleCtor();
extern (C) void _moduleDtor();
extern (C) void thread_joinAll();

//debug=PRINTF;

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

extern (C) void _d_assert_msg( char[] msg, char[] file, uint line )
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
    _STI_monitor_staticctor();
    _STI_critical_init();
    initStaticDataPtrs();
}

alias void delegate( Exception ) ExceptionHandler;

// this is here so users can manually initialize the runtime
// for example, when there is no main function etc.
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
    _STD_critical_term();
    _STD_monitor_staticdtor();
}

// this is here so users can manually terminate the runtime
// for example, when there is no main function etc.
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
int main(char[][] args);

version(NoCMain)
{
	
}
else
{

/***********************************
 * Substitutes for the C main() function.
 * It's purpose is to wrap the call to the D main()
 * function and catch any unhandled exceptions.
 */

extern (C) int main(int argc, char **argv, char** env)
{
    char[][] args;
    int result;

    debug(PRINTF) printf("main ctors\n");
    _STI_monitor_staticctor();
    _STI_critical_init();
    initStaticDataPtrs();

    debug(PRINTF) printf("main args\n");
    // GDC seems to get by without this Windows special case...
    version (Win32)
    {
        wchar_t*  wcbuf = GetCommandLineW();
        size_t    wclen = wcslen(wcbuf);
        int       wargc = 0;
        wchar_t** wargs = CommandLineToArgvW(wcbuf, &wargc);
        assert(wargc == argc);

        char*     cargp = null;
        size_t    cargl = WideCharToMultiByte(65001, 0, wcbuf, wclen, null, 0, null, null);

        cargp = cast(char*) alloca(cargl);
        args  = ((cast(char[]*) alloca(wargc * (char[]).sizeof)))[0 .. wargc];

        for (size_t i = 0, p = 0; i < wargc; i++)
        {
            int wlen = wcslen( wargs[i] );
            int clen = WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, null, 0, null, null);
            args[i]  = cargp[p .. p+clen];
            p += clen; assert(p <= cargl);
            WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, &args[i][0], clen, null, null);
        }
        LocalFree(wargs);
        wargs = null;
        wargc = 0;
    }
    else
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

    debug(PRINTF) printf("main trap exceptions\n");
    bool trapExceptions = rt_trapExceptions;

    void tryExec(void delegate() dg)
    {
        debug(PRINTF) printf("main try exec\n");
        if (trapExceptions)
        {
            try
            {
                dg();
            }
            catch (Exception e)
            {
                e.writeOut(delegate void(char[]s){ console(s); });
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
        debug(PRINTF) printf("main runMain\n");
        result = main(args);
    }

    void runAll()
    {
        debug(PRINTF) printf("main runAll\n");
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

    debug(PRINTF) printf("main dtor\n");
    _STD_critical_term();
    _STD_monitor_staticdtor();

    return result;
}

}
