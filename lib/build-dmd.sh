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

# Check make we have
MAKE=`which gmake`
if [ ! -e "$MAKE" ]
then
    MAKE=`which make`
    if [ ! "`$MAKE --version | grep 'GNU Make'`" ]
    then
        echo 'No supported build tool found.'
        exit 1
    fi
fi

export MAKETOOL=$MAKE


$MAKE clean-all -fdmd-posix.mak           || goerror
$MAKE all install -fdmd-posix.mak SYSTEM_VERSION="$POSIXFLAG"  || goerror
$MAKE clean -fdmd-posix.mak           || goerror
chmod 644 ../tango/core/*.di         || goerror

export HOME=$OLDHOME
