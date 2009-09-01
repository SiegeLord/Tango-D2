@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
make clean-all -fdmd-win32.mak
make all -fdmd-win32.mak
make install -fdmd-win32.mak
make clean -fdmd-win32.mak
set HOME=%TANGO_OLDHOME%