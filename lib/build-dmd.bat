@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
make clean -fdmd-win32.mak
make lib doc install -fdmd-win32.mak
make clean -fdmd-win32.mak
set HOME=%TANGO_OLDHOME%