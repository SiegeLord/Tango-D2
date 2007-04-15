#!/bin/bash
cd "`dirname $0`"

if [ ! "$1" ]
then
    echo 'Use: build-gdc-x.sh <target> [phobos-fragments-directory]'
    exit 1
fi
HOST="$1"
BUILD="`./compiler/gdc/config.guess`"
CONFIGURE_FLAGS=""
if [ "$2" ]
then
    CONFIGURE_FLAGS="--enable-phobos-config-dir=$2"
fi
HOST_ARCH="`echo $HOST | sed 's/-.*//'`"
ADD_CFLAGS=
if [ "$HOST_ARCH" = "powerpc" ]
then
    ADD_CFLAGS="-mregnames"
fi

GDC_VER="`$HOST-gdc --version | grep 'gdc' | sed 's/^.*gdc \([0-9]*\.[0-9]*\).*$/\1/'`"
GDC_MAJOR="`echo $GDC_VER | sed 's/\..*//'`"
GDC_MINOR="`echo $GDC_VER | sed 's/.*\.//'`"

if [ "$GDC_MAJOR" = "0" -a \
     "$GDC_MINOR" -lt "23" ]
then
    echo 'This version of Tango requires GDC 0.23 or newer.'
    exit 1
fi

pushd ./compiler/gdc
./configure --host="$HOST" --build="$BUILD" $CONFIGURE_FLAGS || exit 1
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean -fgdc-posix.mak CC=$HOST-gcc DC=$HOST-gdmd || exit 1
make lib doc install -fgdc-posix.mak CC=$HOST-gcc DC=$HOST-gdmd ADD_CFLAGS="$ADD_CFLAGS" || exit 1
make clean -fgdc-posix.mak CC=$HOST-gcc DC=$HOST-gdmd || exit 1
export HOME=$OLDHOME
