#!/bin/bash

# A simple script to uninstall Tango for GDC
# Copyright (C) 2007  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.

die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: uninstall.sh [--prefix <install prefix>]'
    exit 0
}

cd "`dirname $0`"
dmd --help >& /dev/null || die "gdc not found on your \$PATH!" 1

# 0) Parse arguments
PHOBOS_DIR="`whereis libphobos.a | sed -e 's/libphobos:[ ]*\([^ ]*\)[ ]*.*/\1/' -`"
PHOBOS_DIR="`dirname $PHOBOS_DIR`"
PREFIX="$PHOBOS_DIR/.."
DMD_VER="`gdc --version | head -n 1 | cut -d ' ' -f 3`"

while [ "$#" != "0" ]
do
    if [ "$1" = "--prefix" ]
    then
        PREFIX="$1"
    else
        usage
    fi
    shift
done

if [ ! -e "$PHOBOS_DIR/libphobos.a.phobos" ]
then
    die "tango does not appear to be installed!" 3
fi
rm -rf $PHOBOS_DIR/libgphobos.a $PHOBOS_DIR/libtango.a $PREFIX/import/$DMD_VER/object.d
mv $PREFIX/import/$DMD_VER/object.d.phobos $PREFIX/import/$DMD_VER/object.d
mv $PHOBOS_DIR/libphobos.a.phobos $PHOBOS_DIR/libphobos.a
echo "Done!"
