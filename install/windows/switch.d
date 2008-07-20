// CyberShadow 2007.02.18: switch.exe should to be in dmd/bin, so it can be reachable from PATH

import tango.sys.win32.UserGdi;
import tango.stdc.stringz;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.io.FilePath;
import tango.text.Util;
import tango.text.Ascii;

void main (char[][] args)
{
    if ( args.length == 1 )
    {
        printf(toStringz("Tango switch utility v1.1
Usage:   switch.exe 'phobos|tango'
Example: switch.exe phobos
         ( will switch to Digital Mars phobos.lib )")) ;
        exit(0);
    }

    char[] currentDir;
    bool useMessageBoxes = false;

    void showMessage(char[] msg)
    {
        if(useMessageBoxes)
            MessageBoxA(null, toStringz(msg), "Tango Switch utility\0", 0);
        else
            printf("%s\n", toStringz(msg));
    }
    
    if ( args.length >= 3 )
    {
        // the 2nd command-line parameter is a sign that switch.exe was called 
        // from the Start menu shortcuts, so use Windows MessageBoxes to message 
        // the user instead of printf's
        useMessageBoxes = true;
        currentDir = args[2];
    }
    else
    {
        // attempt to auto-detect library path
        if((new FilePath("..\\lib\\phobos.lib")).exists)
            currentDir = "..\\";
        else
        if((new FilePath("lib\\phobos.lib")).exists)
            currentDir = ".\\";
        else
        {
            // look by the program's location (assume switch.exe is either is ...\dmd\switch.exe or ...\dmd\bin\switch.exe
            char[] commandLine = args[0];
            int pos=locatePrior(commandLine,'\\');
            if(pos<commandLine.length)
            {
                char[] programFolder = commandLine[0..pos+1];
                if((new FilePath(programFolder ~ "..\\lib\\phobos.lib")).exists)
                    currentDir = programFolder ~ "..\\";
                else
                if((new FilePath(programFolder ~ "lib\\phobos.lib")).exists)
                    currentDir = programFolder;
            }
        }
    }
    
    if (currentDir=="")
    {
        showMessage("Error: unable to locate the library files.");
        return;
    }

    char[] tangoLib = currentDir ~ "lib\\tango_phobos.lib";
    char[] phobosLib = currentDir ~ "lib\\dmd_phobos.lib";
    char[] targetLib = currentDir ~ "lib\\phobos.lib";

    // CyberShadow 2007.02.18: adding automated switching of build.cfg (not switching 
    // it messes up include folders and breaks compilation of Phobos programs)
    char[] tangoConf = currentDir ~ "bin\\build.cfg.tango";
    char[] phobosConf = currentDir ~ "bin\\build.cfg.phobos";
    char[] targetConf = currentDir ~ "bin\\build.cfg";

    char[] target = args[1].toLower();

    if ( target == "phobos" ) // switch to Phobos
    {
        // CyberShadow 2007.02.18: FIXME: toStringz is used incorrectly here. 
        // ANSI Windows APIs take Multi-byte character strings as parameters 
        // (see WideCharToMultiByte).

        if((new FilePath(targetLib)).fileSize==(new FilePath(phobosLib)).fileSize)
        {
        	showMessage("You are already using Phobos.");
        	return;
        }
        
        MoveFileA(toStringz(targetConf), toStringz(tangoConf));   // backup the Tango Build config
        MoveFileA(toStringz(phobosConf), toStringz(targetConf));  // put Phobos's Build config in place
        
        if (!CopyFileA(toStringz(phobosLib), toStringz(targetLib), false))
            showMessage("Error: Could not find " ~ phobosLib);
        else
            showMessage("Switched to Phobos");
    }
    else 
    if ( target == "tango" ) // switch to Tango
    {
        if((new FilePath(targetLib)).fileSize==(new FilePath(tangoLib)).fileSize)
        {
        	showMessage("You are already using Tango.");
        	return;
        }
        
        MoveFileA(toStringz(targetConf), toStringz(phobosConf));  // backup the Phobos Build config
        MoveFileA(toStringz(tangoConf), toStringz(targetConf));   // put Tango's Build config in place
        
        if (!CopyFileA(toStringz(tangoLib), toStringz(targetLib), false))
            showMessage("Error: Could not find " ~ tangoLib);
        else
            showMessage("Switched to Tango");
    }
    else
        showMessage("Unrecognized `target' parameter: " ~ target);
}
