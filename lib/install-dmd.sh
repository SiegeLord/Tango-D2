#!/bin/bash

# A simple script to install Tango for DMD
# Copyright (C) 2006-2007  Gregor Richards
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
  --prefix: Install to the specified prefix (absolute path).
  --uninstall: Uninstall tango, switch back to standard phobos.'
    exit 0
}

cd "`dirname $0`"

# 0) Parse arguments
UNINSTALL=0
REPLACE_PHOBOS=0

while [ "$#" != "0" ]
do
    if [ "$1" = "--prefix" ]
    then
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

if [ ! "$PREFIX" ]
then
    PREFIX="/usr/local"
fi

echo "$PREFIX"

if [ "${PREFIX:0:1}" != "/" ]
then
    die "The PREFIX needs to be an absolute path" 1
fi

dmd --help >& /dev/null || die "dmd not found on your \$PATH!" 1

if [ -e "$PREFIX/lib/libphobos.a" ]
then
    REPLACE_PHOBOS=1
fi

# If uninstalling, do that now
if [ "$UNINSTALL" = "1" ]
then
    # revert to phobos if earlier evidence of existense is found
    if [ -e "$PREFIX/lib/libphobos.a.phobos" ]
    then
        mv     $PREFIX/lib/libphobos.a.phobos $PREFIX/lib/libphobos.a
    fi
    if [ -e "$PREFIX/include/d/object.d.phobos" ]
    then
        mv     $PREFIX/include/d/object.d.phobos $PREFIX/include/d/object.d
    fi
    if [ -e "$PREFIX/bin/dmd.conf.phobos" ]
    then
        mv   $PREFIX/bin/dmd.conf $PREFIX/bin/dmd.conf.tango
        mv   $PREFIX/bin/dmd.conf.phobos $PREFIX/bin/dmd.conf
    fi
    # Tango 0.97 installed to this dir
    if [ -e "$PREFIX/import/v1.012" ]
    then
        rm -rf $PREFIX/import/v1.012
    fi
    # Since Tango 0.98
    if [ -e "$PREFIX/include/d/tango/object.di" ]
    then
        rm -rf $PREFIX/include/d/tango/tango
        rm -rf $PREFIX/include/d/tango/std
        rm -f  $PREFIX/include/d/tango/object.di
    fi
    # Since tango 0.99
    if [ -e "$PREFIX/include/d/object.di" ]
    then
        rm -rf $PREFIX/include/d/tango
        rm -rf $PREFIX/include/d/std
        rm -f  $PREFIX/include/d/object.di
    fi

    if [ -e "$PREFIX/lib/libtango.a" ]
    then
		rm -f $PREFIX/lib/libtango.a
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
	if [ -e "$PREFIX/lib/libphobos.a.phobos" ]
	then
		die "You must uninstall your old copy of Tango before installing a new one." 4
	fi
	mv -f $PREFIX/lib/libphobos.a $PREFIX/lib/libphobos.a.phobos
    if [ -e "$PREFIX/include/d/object.d" ]
    then
	    mv -f $PREFIX/include/d/object.d $PREFIX/include/d/object.d.phobos
    fi
fi

create_dmd_conf() {
    cat > $PREFIX/bin/dmd.conf <<EOF
[Environment]
DFLAGS=-I$PREFIX/include/d -version=Tango -version=Posix -L-L"%@P%/../lib"
EOF
}

# Install ...
echo 'Copying files...'
mkdir -p $PREFIX/include/d || die "Failed to create include/d (maybe you need root privileges?)" 5
mkdir -p $PREFIX/lib/ || die "Failed to create $PREFIX/lib (maybe you need root privileges?)" 5
mkdir -p $PREFIX/bin/ || die "Failed to create $PREFIX/bin" 5
cp -pRvf libphobos.a $PREFIX/lib/ || die "Failed to copy libraries" 7
cp -pRvf ../object.di $PREFIX/include/d/object.di || die "Failed to copy source" 8
if [ ! -e "$PREFIX/bin/dmd.conf" ]
then
    create_dmd_conf
else
    # Is it a phobos conf ?
    if [ ! "`grep '\-version=Tango' $PREFIX/bin/dmd.conf`" ]
    then
        mv $PREFIX/bin/dmd.conf $PREFIX/bin/dmd.conf.phobos 
        create_dmd_conf
    else
        echo 'Found Tango enabled dmd.conf, assume it is working and leave it as is'
    fi
fi

die "Done!" 0
