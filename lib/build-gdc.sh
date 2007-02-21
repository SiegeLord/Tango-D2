#!/bin/bash
cd "`dirname $0`"

pushd ./compiler/gdc
./configure || exit 1
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean lib doc install clean -fgdc-posix.mak || exit 1
export HOME=$OLDHOME
