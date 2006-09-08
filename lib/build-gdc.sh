#!/bin/bash
cd "`dirname $0`"

pushd ./compiler/gdc
./configure || exit 1
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean   -fgdc-posix.mak || exit 1
make         -fgdc-posix.mak || exit 1
make install -fgdc-posix.mak || exit 1
make clean   -fgdc-posix.mak || exit 1
export HOME=$OLDHOME
