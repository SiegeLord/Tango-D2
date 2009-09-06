#!/usr/bin/env bash
# returns the name of the qualified object names with a \ appended at the end
# of the given files, useful to build makefile lists
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

sed -n 's/^ *module  *\([a-zA-Z.0-9_][a-zA-Z.0-9_]*\) *;.*/ \1 \\/p' $*
