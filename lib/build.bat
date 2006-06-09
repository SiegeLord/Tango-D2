@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
make clean   -fwin32.mak
make         -fwin32.mak
make install -fwin32.mak
make clean   -fwin32.mak
set HOME=%TANGO_OLDHOME%
pause