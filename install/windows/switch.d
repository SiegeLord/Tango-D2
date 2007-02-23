// CyberShadow 2007.02.18: revert.exe should to be in dmd/bin, so it can be reachable from PATH

import tango.sys.win32.UserGdi;
import tango.stdc.stringz;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.io.FileProxy;
import tango.text.Util;
import tango.text.Ascii;

void main (char[][] args)
{
    if ( args.length == 1 )
    {
        printf(toUtf8z("Tango revert utility v1.1
Usage:   revert.exe 'phobos|tango'
Example: revert.exe phobos
         ( will revert to Digital Mars phobos.lib )")) ;
        exit(0);
    }

    char[] currentDir;
    bool useMessageBoxes = false;

    void showMessage(char[] msg)
    {
        if(useMessageBoxes)
            MessageBoxA(null, toUtf8z(msg), "Tango Revert utility\0", 0);
        else
            printf("%s\n", toUtf8z(msg));
    }
    
    if ( args.length >= 3 )
    {
        // the 2nd command-line parameter is a sign that revert.exe was called 
        // from the Start menu shortcuts, so use Windows MessageBoxes to message 
        // the user instead of printf's
        useMessageBoxes = true;
        currentDir = args[2];
    }
    else
    {
        // attempt to auto-detect library path
        if((new FileProxy("..\\lib\\phobos.lib")).exists)
            currentDir = "..\\";
        else
        if((new FileProxy("lib\\phobos.lib")).exists)
            currentDir = ".\\";
        else
        {
            // look by the program's location (assume revert.exe is either is ...\dmd\revert.exe or ...\dmd\bin\revert.exe
            char[] commandLine = args[0];
            int pos=locatePrior(commandLine,'\\');
            if(pos<commandLine.length)
            {
                char[] programFolder = commandLine[0..pos+1];
                if((new FileProxy(programFolder ~ "..\\lib\\phobos.lib")).exists)
                    currentDir = programFolder ~ "..\\";
                else
                if((new FileProxy(programFolder ~ "lib\\phobos.lib")).exists)
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

    if ( target == "phobos" ) // revert to Phobos
    {
        // CyberShadow 2007.02.18: FIXME: toUtf8z is used incorrectly here. 
        // ANSI Windows APIs take Multi-byte character strings as parameters 
        // (see WideCharToMultiByte).

        if((new FileProxy(targetLib)).getSize==(new FileProxy(phobosLib)).getSize)
        {
        	showMessage("You are already using Phobos.");
        	return;
        }
        
        MoveFileA(toUtf8z(targetConf), toUtf8z(tangoConf));   // backup the Tango Build config
        MoveFileA(toUtf8z(phobosConf), toUtf8z(targetConf));  // put Phobos's Build config in place
        
        if (!CopyFileA(toUtf8z(phobosLib), toUtf8z(targetLib), false))
            showMessage("Error: Could not find " ~ phobosLib);
        else
            showMessage("Switched to Phobos");
    }
    else 
    if ( target == "tango" ) // revert to Tango
    {
        if((new FileProxy(targetLib)).getSize==(new FileProxy(tangoLib)).getSize)
        {
        	showMessage("You are already using Tango.");
        	return;
        }
        
        MoveFileA(toUtf8z(targetConf), toUtf8z(phobosConf));  // backup the Phobos Build config
        MoveFileA(toUtf8z(tangoConf), toUtf8z(targetConf));   // put Tango's Build config in place
        
        if (!CopyFileA(toUtf8z(tangoLib), toUtf8z(targetLib), false))
            showMessage("Error: Could not find " ~ tangoLib);
        else
            showMessage("Switched to Tango");
    }
    else
        showMessage("Unrecognized `target' parameter: " ~ target);
}
