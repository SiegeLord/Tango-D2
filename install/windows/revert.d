import tango.sys.win32.Common;
import tango.stdc.stringz;
import tango.stdc.stdio;
import tango.stdc.stdlib;

void main (char [] [] args)
{
  //  printf("%d",args.length );
  char [] currentDir ;
  if ( args.length == 3 )
    {
      currentDir = args[2];
    }      
  if ( args.length == 2  ) 
    {
      // assume dir is current dur
      currentDir = "";
      return;
    }
  else if ( args.length == 1 )
    {
      printf(toUtf8z("Usage: revert.exe 'phobos|tango' 'C:\\root\\dmd\\dir'\nExample: revert.exe phobos ( will revert to Digital Mars phobos.lib )")) ;
      exit(0);
    }
  


  char [] tangoLib = currentDir ~ "lib\\tango_phobos.lib";
  char [] dmdLib = currentDir ~ "lib\\dmd_phobos.lib";
  char [] phobosLib = currentDir ~ "lib\\phobos.lib";

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
