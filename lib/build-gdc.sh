#!/bin/bash
cd "`dirname $0`"

GDC_VER="`gdc --version | grep 'gdc' | sed 's/^.*gdc \([0-9]*\.[0-9]*\).*$/\1/'`"
GDC_MAJOR="`echo $GDC_VER | sed 's/\..*//'`"
GDC_MINOR="`echo $GDC_VER | sed 's/.*\.//'`"
HOST_ARCH="`./compiler/gdc/config.guess | sed 's/-.*//'`"
ADD_CFLAGS=
if [ "$HOST_ARCH" = "powerpc" -a ! "`./compiler/gdc/config.guess | grep darwin`" ]
then
    ADD_CFLAGS="-mregnames"
fi

if [ "$GDC_MAJOR" = "0" -a \
     "$GDC_MINOR" -lt "23" ]
then
    echo 'This version of Tango requires GDC 0.23 or newer.'
    exit 1
fi

pushd ./compiler/gdc
./configure || exit 1
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean -fgdc-posix.mak || exit 1
make lib doc install -fgdc-posix.mak ADD_CFLAGS="$ADD_CFLAGS" || exit 1
make clean -fgdc-posix.mak || exit 1
chmod 644 ../tango/core/*.di || exit 1

export HOME=$OLDHOME
