import tango.io.device.File;
import tango.io.FilePath;
import tango.io.FileScan;
import tango.io.Stdout;
import tango.sys.Environment;
import tango.text.Util;
import tango.util.ArgParser;


void main( char[][] args )
{
    scope(exit) Stdout.flush;

    auto     parser = new ArgParser;
    char[]   prefix = null;
    bool     uninst = false;

    parser.bind( "--", "prefix",
                 delegate void( char[] val )
                 {
                    require( val[0] == '=', "Invalid parameter format." );
                    prefix = val[1 .. $];
                 } );
    parser.bind( "--", "uninstall",
                 delegate void( char[] val )
                 {
                    uninst = true;
                 } );
    parser.parse( args[1 .. $] );

    auto     binPath = Environment.exePath( "dmd.exe" );
    require( binPath !is null, "DMD installation not found." );
    auto     usePath = new FilePath( "" );
    auto     impPath = new FilePath( "" );
    auto     libPath = new FilePath( "" );

    usePath.set( prefix ? prefix : usePath.set( binPath.parent ).parent );
    require( usePath.exists, "Path specified by prefix does not exist." );
    usePath.path( usePath.toString );

    impPath.set( usePath.path ~ "import" );
    if( !impPath.exists )
        impPath.create();
    impPath.path = impPath.toString;

    libPath.set( usePath.path ~ "lib" );
    if( !libPath.exists )
        libPath.create();
    libPath.path = libPath.toString;


	bool reinstall=false;
    if (binPath.file( "sc.ini.phobos" ).exists) {
        Stdout("Tango is already installed... reinstalling" );
		reinstall=true;
	}

    if( uninst || reinstall )
    {
        if ((!reinstall)||(binPath.file("sc.ini.phobos").exists))
			restoreFile( binPath.file( "sc.ini" ) );
        removeFile( libPath.file( "tango-user-dmd.lib" ) );
        removeFile( libPath.file( "tango-base-dmd.lib" ) );
        removeFile( libPath.file( "tango-base-dmd-dbg.lib" ) );

        removeFile( impPath.file( "object.di" ) );
        removeTree( impPath.file( "tango" ) );
        removeTree( impPath.file( "std" ) );
        removeTree( impPath.file( "rt" ) );
    }
    if (!uninst)
    {
		copyTree( impPath.file( "rt" ), "..\\user" );
		copyTree( impPath.file( "std" ), "..\\user" );
        copyTree( impPath.file( "tango" ), "..\\user" );
        copyFile( impPath.file( "object.di" ), "..\\user" );

        copyFile( libPath.file( "tango-user-dmd.lib" ), ".\\libs" );
        copyFile( libPath.file( "tango-base-dmd.lib" ), ".\\libs" );
        copyFile( libPath.file( "tango-base-dmd-dbg.lib" ), ".\\libs" );

        backupFile( binPath.file( "sc.ini" ) );
        scope(failure) restoreFile( libPath.file( "sc.ini" ) );

        if( prefix )
        {
            writeFile( binPath.file( "sc.ini" ),
                       iniFile( FilePath.stripped( impPath.path ),
                                FilePath.stripped( libPath.path ) ) );
        }
        else
        {
            writeFile( binPath.file( "sc.ini" ),
                       iniFile( "%@P%\\..\\import",
                                "%@P%\\..\\lib" ) );
        }
    }
}


void backupFile( FilePath fp, char[] suffix = ".phobos" )
{
    char[]  orig = fp.file.dup;
    char[]  back = orig ~ suffix;

    require( !fp.file( back ).exists, back ~ " already exists." );
    require( fp.file( orig ).exists, orig ~ " does not exist." );
    fp.file( orig ).rename( fp.path ~ back );
}


void restoreFile( FilePath fp, char[] suffix = ".phobos" )
{
    char[]  orig = fp.file.dup;
    char[]  back = orig ~ suffix;

    // NOTE: The backup may not exist if Tango was installed using
    //       the --prefix option.
    //require( fp.file( back ).exists, back ~ " does not exist." );
    if( !fp.file( back ).exists )
        return;

    removeFile( fp.file( orig ) );
    fp.file( back ).rename( fp.path ~ orig );
}


void removeFile( FilePath fp )
{
    if( fp.exists )
        fp.remove();
}


void writeFile( FilePath fp, lazy char[] buf )
{
    scope fc = new File( fp.toString, File.WriteCreate );
    scope(exit) fc.close();
    fc.output.write( buf );
}


void copyFile( FilePath dstFile, char[] srcPath )
{
    scope srcFc = new File( FilePath.padded( srcPath ) ~ dstFile.file,
                            File.ReadExisting );
    scope(exit) srcFc.close();
    scope dstFc = new File( dstFile.toString, File.WriteCreate );
    scope(exit) dstFc.close();
    dstFc.copy( srcFc );
}


void copyTree( FilePath dstPath, char[] srcPath )
{
    bool matchAll( FilePath fp, bool isDir )
    {
        return true;
    }

    scope   scan    = new FileScan;
    scope   dstFile = new FilePath( "" );

    srcPath = FilePath.padded( srcPath ) ~ dstPath.file;
    scan.sweep( srcPath, &matchAll );
    dstFile.path = dstPath.toString;

    foreach( f; scan.folders )
    {
        dstFile.set( dstPath.toString ~ f.toString[srcPath.length .. $] );
        if( !dstFile.exists )
            dstFile.create();
    }

    foreach( f; scan.files )
    {
        dstFile.set( dstPath.toString ~ f.toString[srcPath.length .. $] );
        copyFile( dstFile, f.path );
    }
}


void removeTree( FilePath root )
{
    if( !root.exists )
        return;

    bool matchAll( FilePath fp, bool isDir )
    {
        return true;
    }

    scope scan = new FileScan;

    scan.sweep( root.toString, &matchAll );

    foreach( f; scan.files )
    {
        f.remove();
    }

    foreach( f; scan.folders )
    {
        f.remove();
    }
}


void require( bool result, char[] msg )
{
    if( !result )
        throw new Exception( msg );
}


char[] iniFile( char[] impPath, char[] libPath )
{
    return "[Version]\n"
           "version=7.51 Build 020\n"
           "\n"
           "[Environment]\n"
           "LIB=\"" ~ libPath ~ "\"\n"
           "DFLAGS=\"-I" ~ impPath ~ "\" -version=Tango -defaultlib=tango-base-dmd.lib -debuglib=tango-base-dmd-dbg.lib -L+tango-user-dmd.lib\n"
           "LINKCMD=%@P%\\link.exe\n";
}
