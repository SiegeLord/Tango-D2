pushd ..\runtime\common\tango\sys\win32

dmd -I..\..\.. -c -inline -release -O Macros.d Process.d Types.d UserGdi.d
lib -c -n tango-win32-dmd.lib Macros.obj Process.obj Types.obj UserGdi.obj

mkdir ..\..\..\..\..\..\build\libs
move /y tango-win32-dmd.lib ..\..\..\..\..\..\build\libs\.

copy /y Macros.di   ..\..\..\..\..\..\user\tango\sys\win32
copy /y Process.di  ..\..\..\..\..\..\user\tango\sys\win32
copy /y Types.di    ..\..\..\..\..\..\user\tango\sys\win32
copy /y UserGdi.di  ..\..\..\..\..\..\user\tango\sys\win32
del Macros.di    Macros.obj
del Process.di   Process.obj
del Types.di     Types.obj
del UserGdi.di   UserGdi.obj
popd
