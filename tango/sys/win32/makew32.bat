copy /y UserGdi.di   UserGdi.d
copy /y Types.di     Types.d
copy /y Macros.di    Macros.d

dmd -c -inline -release -O UserGdi.d Types.d Macros.d
lib -c -n usergdi32.lib UserGdi.obj Types.obj Macros.obj

del UserGdi.d   UserGdi.obj
del Types.d     Types.obj
del Macros.d    Macros.obj
