@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
make clean lib doc install clean -fdmd-win32.mak
set HOME=%TANGO_OLDHOME%
pause