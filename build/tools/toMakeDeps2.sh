#!/usr/bin/env bash
# transforms the dependencies from the new xfBuild format to make format
# the regex is not perfect and will break for filepaths with "():" in them.
# keeps all dependencies, probably one could filter them and keep only the ones 
# of the first file, or express them as deps on the .d files
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

sed 's/\([a-zA-Z0-9_.][a-zA-Z0-9_.]*\) ([^)]*) : [a-z]* *[a-z]* : \([a-zA-Z0-9_.][a-zA-Z0-9_.]*\) .*$/\1.o : \2.o/' $*

