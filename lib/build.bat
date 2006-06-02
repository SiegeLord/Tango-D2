@echo off
make clean   -fwin32.mak
make         -fwin32.mak
make install -fwin32.mak
make clean   -fwin32.mak
pause