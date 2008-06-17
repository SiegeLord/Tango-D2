#!/usr/bin/env bash
cd "`dirname $0`"

while [ "$#" != "0" ]
do
    case "$1" in
        --debug)
            DEBUG=1
            ;;
    esac
    shift
done
 
# Allow gdc and gdmd to be overriden
if [ "$GDC" = "" ]
then
    export GDC=${GDC_PREFIX}gdc${GDC_POSTFIX}
fi
if [ "$GDMD" = "" ]
then
    export GDMD=${GDC_PREFIX}gdmd${GDC_POSTFIX}
fi

GDC_VER="`$GDC --version | grep 'gdc' | sed 's/^.*gdc \(pre\-\{0,1\}release \)*\([0-9]*\.[0-9]*\).*$/\2/'`"
GDC_MAJOR="`echo $GDC_VER | sed 's/\..*//'`"
GDC_MINOR="`echo $GDC_VER | sed 's/.*\.//'`"
HOST_ARCH="`./compiler/gdc/config.guess | sed 's/-.*//'`"
ADD_CFLAGS=
if [ "$HOST_ARCH" = "powerpc" -a ! "`./compiler/gdc/config.guess | grep darwin`" ]
then
    ADD_CFLAGS="-mregnames"
fi

if [ "$DEBUG" = "1" ]
then
    ADD_CFLAGS="$ADD_CFLAGS -g"
fi

if [ "$GDC_MAJOR" = "0" -a \
     "$GDC_MINOR" -lt "23" ]
then
    echo 'This version of Tango requires GDC 0.23 or newer.'
    exit 1
fi

# Make sure object.di is present for clean GDC installs
cp ../object.di compiler/gdc/object.di

# Make sure scripts are installable (typically zip doesn't preserve x bit)
chmod a+x compiler/gdc/configure
chmod a+x compiler/gdc/config.guess

pushd ./compiler/gdc
./configure || exit 1
popd

# Remove object.di again
rm compiler/gdc/object.di

# Check make we have
MAKE=`which gmake`
if [ ! -e "$MAKE" ]
then
    MAKE=`which make`
    if [ ! `$MAKE --version | grep 'GNU Make'` ]
    then
        echo 'No supported build tool found.'
        exit 1
    fi
fi

export MAKETOOL=$MAKE

OLDHOME=$HOME
export HOME=`pwd`
$MAKE clean -fgdc-posix.mak DC="$GDMD" || exit 1
$MAKE lib doc install -fgdc-posix.mak DC="$GDMD" ADD_CFLAGS="$ADD_CFLAGS" || exit 1
$MAKE clean -fgdc-posix.mak DC="$GDMD" || exit 1
chmod 644 ../tango/core/*.di || exit 1

export HOME=$OLDHOME
