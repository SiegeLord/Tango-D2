import tango.io.stream.Map;
import tango.sys.Process;
import tango.io.FileSystem;
import tango.io.FilePath;
import tango.io.device.File;
import tango.io.model.IFile;

import tango.io.Stdout;

import tango.time.WallClock;

char[] workdir;
char[] wcdir;
char[] repourl;
char[] projname;
char[] buildcmd;
char[] chmodfiles;
char[] rmpaths;
char[] dlpath;

int main(char[][] args)
{
    if (args.length < 2) {
        Stderr("Provide a path to a config file").newline;
        return 1;
    }

    // Read config
    void configReader(char[] name, char[]value)
    {
        switch (name) {
        case "workdir":
            workdir = value;
            break;
        case "wcdir":
            wcdir = value;
            break;
        case "repourl":
            repourl = value;
            break;
        case "projname":
             projname = value;
             break;
        case "buildcmd":
             buildcmd = value;
             break;
        case "chmodfiles":
             chmodfiles = value;
             break;
        case "rmpaths":
             rmpaths = value;
             break;
        case "dlpath":
             dlpath = value;
             break;
           default:
            break;
        }

        return;
    }

    auto props = new MapInput!(char)(new File(args[1]));
    foreach (name, value; props)
             configReader (name, value);
    //props.load(args[1], &configReader);
    props.close;


    // Enter work directory
    FileSystem.setDirectory(workdir);
    // Check out repository if working copy don't exist, update it if it do
    auto wc = new FilePath(wcdir);
    if (!wc.exists) {
        Stdout("!! Checking out working copy from repository").newline;
        auto svnco = new Process("svn co " ~ repourl ~ " " ~ wcdir, null);
        svnco.execute();
        auto result = svnco.wait();
        if (result.reason != Process.Result.Exit) {
            Stderr("Was not able to check out working copy from repository").newline;
            return 1;
        }
    }
    else {
        Stdout("!! Updating working copy").newline;
        FileSystem.setDirectory(wcdir);
        auto svnup = new Process("svn up", null);
        svnup.execute();
        auto result = svnup.wait();
        if (result.reason != Process.Result.Exit) {
            Stderr("Was not able to update working copy").newline;
            return 1;
        }
    }

    // Make sure we're still in work directory
    FileSystem.setDirectory(workdir);

    // export wc to dir to be packaged, will need to have the name of the package

    Stdout("!! Exporting from working copy for packaging").newline;
    auto dt = WallClock.toDate;
    char[] datestr; 
    datestr = Stdout.layout.sprint(new char[10], "{}{:2}{:2}", dt.date.year, dt.date.month, dt.date.day);
    char[] packdirdate = projname ~ "-src-SNAPSHOT-" ~ datestr;
    char[] packdircurrent = projname ~ "-src-SNAPSHOT-CURRENT"; 

    auto pd = new FilePath(packdirdate);
    if (pd.exists) {
        Stdout("!! Packaging dir already exists, removing before recreating").newline;
        auto rmdir = new Process("rm -rf " ~ packdirdate, null);
        rmdir.execute();
        auto result = rmdir.wait();
        if (result.reason != Process.Result.Exit) {
            Stderr("Was not able to remove old package dir").newline;
            return 1;
        }
    }

    auto svnexp = new Process("svn export " ~ wcdir ~ " " ~ packdirdate, null);
    svnexp.execute();
    auto result = svnexp.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to export working copy").newline;
        return 1;
    }
 
    // enter packagedir/lib
    Stdout("!! Generate files").newline;
    FileSystem.setDirectory(packdirdate ~ FileConst.PathSeparatorString ~ "lib");

    // run build-*.*
    auto bld = new Process(buildcmd, null);
    bld.execute();
    Stderr.stream.copy(bld.stderr);
    result = bld.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to build ").newline;
        return 1;
    }
 
    // enter package root dir
    FileSystem.setDirectory(workdir ~ FileConst.PathSeparatorString ~ packdirdate);

    // change access to generated files
    Stdout("!! Changing access rights").newline;
    auto chmod = new Process("chmod 644 " ~ chmodfiles, null);
    chmod.execute();
    Stderr.stream.copy(chmod.stderr);
    result = chmod.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to change access rights").newline;
        return 1;
    }
 
    // remove patches/ , install/win32/, doc/ and more
    Stdout("!! Removing " ~ rmpaths).newline;
    auto rm = new Process("rm -rf " ~ rmpaths, null);
    rm.execute();
    Stderr.stream.copy(rm.stderr);
    result = rm.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to remove paths").newline;
        return 1;
    }
 
    // enter workdir
    FileSystem.setDirectory(workdir);

    // create zip, etc
    Stdout("!! Creating .tar.gz").newline;
    auto targz = new Process("tar czf " ~ packdirdate ~ ".tar.gz " ~ packdirdate, null);
    targz.execute();
    Stderr.stream.copy(targz.stderr);
    result = targz.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to create .tar.gz").newline;
        return 1;
    }

    Stdout("!! Creating .zip").newline;
    auto zip = new Process("zip -r " ~ packdirdate ~ " " ~ packdirdate, null);
    zip.execute();
    Stderr.stream.copy(zip.stderr);
    result = zip.wait();
    if (result.reason != Process.Result.Exit) {
        Stderr("Was not able to create .zip").newline;
        return 1;
    }

    auto dldir = new FilePath(dlpath);
    if (!dldir.exists)
        dldir.createFolder();

    auto datetgz = new FilePath(packdirdate ~ ".tar.gz");
    auto dltgz = new FilePath(dlpath ~ FileConst.PathSeparatorString ~ datetgz.toString);
    datetgz.rename(dltgz);
    
    auto datezip = new FilePath(packdirdate ~ ".zip");
    auto dlzip = new FilePath(dlpath ~ FileConst.PathSeparatorString ~ datezip.toString);
    datezip.rename(dlzip);
 
    auto currenttgz = new FilePath(dlpath ~ FileConst.PathSeparatorString ~ packdircurrent ~ ".tar.gz");
    currenttgz.copy(datetgz.toString);
 
    auto currentzip = new FilePath(dlpath ~ FileConst.PathSeparatorString ~ packdircurrent ~ ".zip");
    currentzip.copy(datezip.toString);

    return 0;
}
