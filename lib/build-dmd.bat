@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
make clean   -fdmd-win32.mak
make         -fdmd-win32.mak
make install -fdmd-win32.mak
make clean   -fdmd-win32.mak
set HOME=%TANGO_OLDHOME%
pause