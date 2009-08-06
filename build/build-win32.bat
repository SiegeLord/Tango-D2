pushd ..\runtime\common\tango\sys\win32

dmd -I..\..\.. -c -inline -release -O Types.d UserGdi.d
lib -c -n tango-win32-dmd.lib Types.obj UserGdi.obj

mkdir ..\..\..\..\..\..\build\libs
move /y tango-win32-dmd.lib ..\..\..\..\..\..\build\libs\.

copy /y Types.di    ..\..\..\..\..\..\user\tango\sys\win32
copy /y UserGdi.di  ..\..\..\..\..\..\user\tango\sys\win32
del Types.di     Types.obj
del UserGdi.di   UserGdi.obj
popd
