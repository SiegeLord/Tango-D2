#!/bin/bash
cd "`dirname $0`"

pushd ./compiler/gdc
./configure || exit 1
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean -fgdc-posix.mak || exit 1
make lib doc install -fgdc-posix.mak || exit 1
make clean -fgdc-posix.mak || exit 1
export HOME=$OLDHOME
