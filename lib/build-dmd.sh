#!/usr/bin/env bash

OLDHOME=$HOME
export HOME=`pwd`

goerror(){
    export HOME=$OLDHOME
    echo "="
    echo "= *** Error ***"
    echo "="
    exit 1
}

# Version specific settings
. dmdinclude
dmdsettings

make clean-all -fdmd-posix.mak           || goerror
make all install -fdmd-posix.mak SYSTEM_VERSION="$POSIXFLAG"  || goerror
make clean -fdmd-posix.mak           || goerror
chmod 644 ../tango/core/*.di         || goerror

export HOME=$OLDHOME
