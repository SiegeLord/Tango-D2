#!/bin/bash

# A simple script to install Tango for GDC
# Copyright (C) 2006  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.

CROSS=""

die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: install-gdc.sh [--inplace] [--prefix <install prefix>]
Options:
  --inplace: Don'\''t install anywhere, just keep the installation in-place.
             (Not recommended, doesn'\''t work without -I)
  --prefix: Install to the specified prefix.
  --uninstall: Uninstall tango, switch back to standard phobos.'
    exit 0
} #'

cd "`dirname $0`"

# 0) Parse arguments
INPLACE=0
SETPREFIX=0
UNINSTALL=0

while [ "$#" != "0" ]
do
    if [ "$1" = "--inplace" ]
    then
        INPLACE=1
    elif [ "$1" = "--prefix" ]
    then
        SETPREFIX=1
        shift

        PREFIX="$1"
    elif [ "$1" = "--uninstall" ]
    then
        UNINSTALL=1
    elif [ "$1" = "--cross" ]
    then
        shift
        CROSS="$1-"
    else
        usage
    fi
    shift
done

${CROSS}gdc --help >& /dev/null || die "gdc not found on your \$PATH!" 1

GPHOBOS_DIR="`${CROSS}gdc -print-file-name=libgphobos.a`"
GPHOBOS_DIR="`dirname $GPHOBOS_DIR`"

# If we have which, use it to get the prefix
which gdc >& /dev/null
if [ "$?" = "0" ]
then
    PREFIX="`which ${CROSS}gdc`"
    PREFIX="`dirname $PREFIX`/.."
else
    PREFIX="$GPHOBOS_DIR/.."
fi

# If libgphobos.a isn't installed, make it up
if [ -n "$GPHOBOS_DIR" -o "$GPHOBOS_DIR" = "." ]
then
    GPHOBOS_DIR="$PREFIX/lib"
fi

GDC_VER="`${CROSS}gdc -dumpversion`"
GDC_MCH="`${CROSS}gdc -dumpmachine`"

if [ "$INPLACE" = "1" -a \
     "$SETPREFIX" = "1" ]
then
    die "Cannot both set a prefix and do an in-place install." 2
fi

# If uninstalling, do that now
if [ "$UNINSTALL" = "1" ]
then
    if [ ! -e "$GPHOBOS_DIR/libgphobos.a.phobos" ]
    then
        die "tango does not appear to be installed!" 3
    fi
    if [ "$INPLACE" = "0" ]
    then
        rm -rf $GPHOBOS_DIR/libgphobos.a $PREFIX/include/d/$GDC_VER/object.d
        mv $PREFIX/include/d/$GDC_VER/object.d.phobos $PREFIX/include/d/$GDC_VER/object.d
        mv $GPHOBOS_DIR/libgphobos.a.phobos $GPHOBOS_DIR/libgphobos.a
    fi
    die "Done!" 0
fi

# Sanity check
if [ ! -e libgphobos.a ]
then
    die "You must run build-gdc.sh before running install-gdc.sh" 4
fi

# Back up the original files
if [ -e "$GPHOBOS_DIR/libgphobos.a" -a \
     ! -e "$GPHOBOS_DIR/libgphobos.a.phobos" ]
then
    mv -f $GPHOBOS_DIR/libgphobos.a $GPHOBOS_DIR/libgphobos.a.phobos
    mv -f $PREFIX/include/d/$GDC_VER/object.d $PREFIX/include/d/$GDC_VER/object.d.phobos
fi

# Install ...
if [ "$INPLACE" = "0" ]
then
    echo 'Copying files...'
    mkdir -p $PREFIX/include/d/$GDC_VER || die "Failed to create include/d/$GDC_VER (maybe you need root privileges?)" 5
    cp -pRvf libgphobos.a $GPHOBOS_DIR || die "Failed to copy libraries" 7
    cp -pRvf ../object.di $PREFIX/include/d/$GDC_VER/object.d || die "Failed to copy source" 8
    if [ ! -e $PREFIX/include/d/$GDC_VER/gcc ]
    then
	mkdir $PREFIX/include/d/$GDC_VER/gcc || die "Failed to create $PREFIX/include/d/$GDC_VER/gcc" 9
	cp -pRvf compiler/gdc/gcc/*.d $PREFIX/include/d/$GDC_VER/gcc || die "Failed to install gcc internals." 10
    fi
fi

die "Done!" 0
