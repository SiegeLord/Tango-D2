#!/bin/bash

# A simple script to install Tango for DMD
# Copyright (C) 2006  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.
#
# Modifications by Alexander Panek, Lars Ivar Igesund

die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: install-dmd.sh [--inplace] [--prefix <install prefix>]
Options:
  --inplace: Don'\''t install anywhere, just keep the installation in-place.
             (Not recommended, doesn'\''t work without -I)
  --prefix: Install to the specified prefix.
  --uninstall: Uninstall tango, switch back to standard phobos.'
    exit 0
}

cd "`dirname $0`"

# 0) Parse arguments
INPLACE=0
SETPREFIX=0
UNINSTALL=0
REPLACE_PHOBOS=0

PREFIX="/usr/local"

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
    else
        usage
    fi
    shift
done





dmd --help >& /dev/null || die "dmd not found on your \$PATH!" 1

PHOBOS_DIR="`whereis libphobos.a | sed -e 's/libphobos:[ ]*\([^ ]*\)[ ]*.*/\1/' -`"
if [ "$PHOBOS_DIR" ]
then
    PHOBOS_DIR="`dirname $PHOBOS_DIR`"
	REPLACE_PHOBOS=1
fi

which --version >& /dev/null
if [ "$?" = "0" ]
then
	PREFIX="`which dmd`"
	PREFIX="`dirname $PREFIX`/.."
	if [ ! "$PHOBOS_DIR" ]
	then
		PHOBOS_DIR="$PREFIX/lib"
		REPLACE_PHOBOS=1
	fi
else
	if [ "$REPLACE_PHOBOS" = "1" ]
	then
		PREFIX="$PHOBOS_DIR/.."
	fi
fi

if [ "$INPLACE" = "1" -a \
     "$SETPREFIX" = "1" ]
then
    die "Cannot both set a prefix and do an in-place install." 2
fi

# If uninstalling, do that now
if [ "$UNINSTALL" = "1" ]
then
    if [ ! -e "$PREFIX/lib/libphobos.a.phobos" ]
    then
		rm -f $PREFIX/lib/libphobos.a
		rm -f $PREFIX/lib/libtango.a
        if [ -e "$PREFIX/import/v1.012" ]
        then
            rm -rf $PREFIX/import/v1.012
        fi
        if [ -e "$PREFIX/import/object.di" ]
        then
            rm -f $PREFIX/import/object.di
            rm -rf $PREFIX/import/std
            rm -rf $PREFIX/import/tango
        fi
        if [ -e "$PREFIX/import/tango" ]
        then
            rm -rf $PREFIX/import/tango
        fi
	else
		if [ "$INPLACE" = "0" ]
		then
			rm -f  $PHOBOS_DIR/libphobos.a $PREFIX/import/object.di
			mv     $PHOBOS_DIR/libphobos.a.phobos $PHOBOS_DIR/libphobos.a
            if [ -e "$PREFIX/import/object.d.phobos" ]
            then
			    mv     $PREFIX/import/object.d.phobos $PREFIX/import/object.d
            fi
		fi
    fi

    die "Done!" 0
fi


# Sanity check
if [ ! -e libphobos.a ]
then
    die "You must run build-dmd.sh before running install-dmd.sh" 4
fi

# Back up the original files
if [ "$REPLACE_PHOBOS" = "1" ]
then
	if [ -e "$PHOBOS_DIR/libphobos.a.phobos" ]
	then
		die "You must uninstall your old copy of Tango before installing a new one." 4
	fi
	mv -f $PHOBOS_DIR/libphobos.a $PHOBOS_DIR/libphobos.a.phobos
    if [ -e "$PREFIX/import/object.d" ]
    then
	    mv -f $PREFIX/import/object.d $PREFIX/import/object.d.phobos
    fi
fi

# Install ...
if [ "$INPLACE" = "0" ]
then
    echo 'Copying files...'
    mkdir -p $PREFIX/import/tango || die "Failed to create import (maybe you need root privileges?)" 5
	mkdir -p $PREFIX/lib/ || die "Failed to create $PREFIX/lib (maybe you need root privileges?)" 5
	mkdir -p $PREFIX/bin/ || die "Failed to create $PREFIX/bin" 5
    cp -pRvf libphobos.a $PREFIX/lib/ || die "Failed to copy libraries" 7
    cp -pRvf ../object.di $PREFIX/import/tango/object.di || die "Failed to copy source" 8
	cat > $PREFIX/bin/dmd.conf <<EOF
[Environment]
DFLAGS=-I$PREFIX/import/tango -version=Tango -version=Posix -L-L"%@P%/../lib"
EOF
fi

die "Done!" 0
