import tango.os.windows.c.windows;
import tango.os.windows.c.shellapi;
// link against shell32.lib

/*
 * Pass on all the real work to the standard main function.
 */
//extern (C) int main( int argc, char** argv );
extern (C) int wmain( int argc, wchar** argv );

extern (Windows) int WinMain( HINSTANCE hInstance,
        	                  HINSTANCE hPrevInstance,
	                          LPSTR     lpCmdLine,
	                          int       nCmdShow )
{
    int       argc;
    wchar_t** argv;
    int       rval;

    argv = CommandLineToArgvW( GetCommandLineW(), &argc );
    rval = wmain( argc, argv );
    LocalFree( argv );
    return rval;
}