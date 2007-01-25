copy /y Common.di    Common.d
copy /y Types.di     Types.d
copy /y Utilities.di Utilities.d

dmd -c -inline -release -O Common.d Types.d Utilities.d
lib -c -n tangow32.lib Common.obj Types.obj Utilities.obj

del Common.d    Common.obj
del Types.d     Types.obj
del Utilities.d Utilities.obj
