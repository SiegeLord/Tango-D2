pushd ..\tango\sys\win32
copy /y Macros.di   Macros.d
copy /y Process.di  Process.d
copy /y Types.di    Types.d
copy /y UserGdi.di  UserGdi.d

dmd -I..\..\.. -c -inline -release -O Macros.d Process.d Types.d UserGdi.d
lib -c -n usergdi32.lib Macros.obj Process.obj Types.obj UserGdi.obj

move /y usergdi32.lib ..\..\..\lib\.

del Macros.d    Macros.obj
del Process.d   Process.obj
del Types.d     Types.obj
del UserGdi.d   UserGdi.obj
popd
