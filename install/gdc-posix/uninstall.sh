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
    echo 'Usage: uninstall-gdc.sh [--prefix <install prefix>]
Options:
  --prefix: Install to the specified prefix.'
    exit 0
}

cd "`dirname $0`"
gdc --help >& /dev/null || die "gdc not found on your \$PATH!" 1

# 0) Parse arguments
GPHOBOS_DIR="`gdc -print-file-name=libgphobos.a`"
GPHOBOS_DIR="`dirname $GPHOBOS_DIR`"
PREFIX="$GPHOBOS_DIR/.."
GDC_VER="`gdc --version | head -n 1 | cut -d ' ' -f 3`"

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

if [ ! -e "$GPHOBOS_DIR/libgphobos.a.phobos" ]
then
    die "tango does not appear to be installed!" 3
fi
rm -rf $GPHOBOS_DIR/libgphobos.a $GPHOBOS_DIR/libtango.a $PREFIX/include/d/$GDC_VER/object.d
mv $PREFIX/include/d/$GDC_VER/object.d.phobos $PREFIX/include/d/$GDC_VER/object.d
mv $GPHOBOS_DIR/libgphobos.a.phobos $GPHOBOS_DIR/libgphobos.a
echo "Done!"
