@echo off
set TANGO_OLDHOME=%HOME%
set HOME=%CD%
build-tango-app.exe
set HOME=%TANGO_OLDHOME%