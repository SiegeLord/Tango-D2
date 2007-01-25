import tango.sys.win32.Common;
//import tango.sys.windows.winuser;
import tango.stdc.stringz;

void main (char [] [] args)
{

  if ( args.length < 2 ) return;

  char [] tangoLib = args[2] ~ "lib\\tango_phobos.lib";
  char [] dmdLib = args[2] ~ "lib\\dmd_phobos.lib";
  char [] phobosLib = args[2] ~ "lib\\phobos.lib";

  if ( args[1] == "phobos" ) // revert to phobos
    {
      if ( !CopyFileA(toUtf8z(dmdLib),toUtf8z(phobosLib),false ) )       MessageBoxA(HWND_DESKTOP,toUtf8z("Error: Could not find " ~ dmdLib ), toUtf8z("Error"),0L);
      else MessageBoxA(HWND_DESKTOP,"Reverted to Phobos\0","Reverted to Phobos\0",0L);
    }
  else if ( args[1] == "tango" ) // revert to tango
    {

      if ( !CopyFileA(toUtf8z(tangoLib),toUtf8z(phobosLib),false )) MessageBoxA(HWND_DESKTOP,toUtf8z("Error: Could not find " ~ tangoLib ),toUtf8z("Error"),0L);
      else MessageBoxA(HWND_DESKTOP,"Reverted to Tango\0","Reverted to Tango\0",0L);
    }





}
