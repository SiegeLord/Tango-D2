module build_tango;

import tango.io.device.File;
import tango.io.FileScan;
import tango.io.Stdout;
import tango.sys.Process;
import tango.text.Util;
import Integer = tango.text.convert.Integer;


void main( char[][] args )
{
    scope(exit) Stdout.flush;

    auto    outf = new File( "tango.lsp", File.ReadWriteCreate );
    auto    scan = new FileScan;
    char[]  path = "..\\user\\tango";
    char[]  list = null;

    if( args.length > 1 )
        path = args[1] ~ "\\tango";

    outf.write( "-c -n -p256\nlibs\\tango-user-dmd.lib\n" );
    foreach( file; scan( path, ".d" ).files )
    {
        if( filter( file ) )
            continue;
        char[] temp = objname( file );
        exec( "dmd -c -inline -release -O -I..\\user " ~
              "-of" ~ objname( file ) ~ " " ~
              file.toString );
        outf.write( temp ~ "\n" );
        list ~= " " ~ temp;
        delete temp;
    }
    outf.close;
    exec( "lib @tango.lsp" );
    //exec( "cmd /q /c del tango.lsp" ~ list );
    exec( "cmd /q /c del tango.lsp *.obj" );
}


bool filter( FilePath file )
{
    return containsPattern( file.folder, "posix"   ) ||
           containsPattern( file.folder, "linux"   ) ||
           containsPattern( file.folder, "darwin"  ) ||
           containsPattern( file.name,   "Posix"   ) ||
           containsPattern( file.folder, "freebsd" );
}


char[] objname( FilePath file )
{
    size_t pos = 0;
    char[] folder = file.dup.native.folder;
    char[] name = folder;
    foreach( elem; name )
    {
        if( elem == '.' || elem == '\\' )
        {
            ++pos; continue;
        }
        break;
    }
    return folder[pos .. $].dup.replace( '\\', '-' ) ~ file.name ~ ".obj";
}


void exec( char[] cmd, char[] workDir = null )
{
    exec( split( cmd, " " ), null, workDir );
}


void exec( char[][] cmd, char[] workDir = null )
{
    exec( cmd, null, workDir );
}


void exec( char[] cmd, char[][char[]] env, char[] workDir = null )
{
    exec( split( cmd, " " ), env, workDir );
}


void exec( char[][] cmd, char[][char[]] env, char[] workDir = null )
{
    scope auto    proc = new Process( cmd, env );
    
    // env must not be null for vista
    if( env is null ) proc.copyEnv( true );
    if( workDir ) proc.workDir = workDir;

    foreach( str; cmd )
        Stdout( str )( ' ' );

    // let console output be line buffered
    Stdout.newline;
    proc.execute();
    Stdout.stream.copy( proc.stdout );
    Stdout.stream.copy( proc.stderr );
    auto result = proc.wait();
    if( result.reason != Process.Result.Exit )
        throw new Exception( result.toString() );
}
