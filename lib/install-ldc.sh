#!/bin/bash

# A simple script to install Tango for LDC

die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: install-ldc.sh [--prefix <install prefix>]
Options:
  --prefix: Install to the specified prefix.'
    exit 0
} #'

cd "`dirname $0`"

# 0) Parse arguments
INPLACE=0
SETPREFIX=0

while [ "$#" != "0" ]
do
    if [ "$1" = "--prefix" ]
    then
        SETPREFIX=1
        shift

        PREFIX="$1"
    else
        usage
    fi
    shift
done

which ldc || die "ldc not found on your \$PATH!" 1

if [ "$SETPREFIX" = "0" ]
then
    # If we have which, use it to get the prefix
    which ldc >& /dev/null
    if [ "$?" = "0" ]
    then
        PREFIX="`which ldc`"
        PREFIX="`dirname $PREFIX`"
        PREFIX="`dirname $PREFIX`"
    else
        PREFIX="$GPHOBOS_DIR/.."
    fi
fi

LIB_DIR="$PREFIX/lib"

LDC_VER="`ldc -dumpversion`"
LDC_MCH="`ldc -dumpmachine`"

# Sanity check
if [ ! -e libtango-base-ldc.a ]
then
    die "You must run build-ldc.sh before running install-ldc.sh" 4
fi

echo 'Copying files...'
cp -pRvf libtango-base-ldc*.a $LIB_DIR || die "Failed to copy libraries" 7
mkdir -p $PREFIX/include/d/ldc
cp -pRvf ../object.di $PREFIX/include/d/object.di || die "Failed to copy source" 8
for f in compiler/ldc/ldc/*.d ; do
 ff=`basename "$f"`
 cp -pRvf "$f" "$PREFIX/include/d/ldc/${ff}i" || die "Failed to copy ldc intrinsic" 9
done
die "Done!" 0
