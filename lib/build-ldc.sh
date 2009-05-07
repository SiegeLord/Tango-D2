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

make clean-all -fldc-posix.mak       || goerror
make all install -fldc-posix.mak     || goerror
make clean -fldc-posix.mak           || goerror
chmod 644 ../tango/core/*.di         || goerror

export HOME=$OLDHOME
