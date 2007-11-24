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
  --altbin: Use an alternate path component for the DMD binary, "bin" is default, "-" will
                set it to empty.
  --altlib: Use an alternate path component for the library files, "lib" is default, "-" will
                set it to empty.
  --uninstall: Uninstall Tango, switch back to standard Phobos.
  --verify: Will verify installation.'
    exit 0
}

cd "`dirname $0`"

# 0) Parse arguments
UNINSTALL=0
VERIFY=0
BIN="bin"
LIB="lib"

while [ "$#" != "0" ]
do
    if [ "$1" = "--prefix" ]
    then
        shift

        PREFIX="$1"
    elif [ "$1" = "--altbin" ]
    then
        shift

        if [ "$1" = "-" ]
        then
            BIN=""
        else
            BIN="$1"
        fi
    elif [ "$1" = "--altlib" ]
    then
        shift

        if [ "$1" = "-" ]
        then
            LIB=""
        else
            LIB="$1"
        fi
    elif [ "$1" = "--uninstall" ]
    then
        UNINSTALL=1
    elif [ "$1" = "--verify" ]
    then
        VERIFY=1
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

# Verify that PREFIX is absolute
if [ "${PREFIX:0:1}" != "/" ]
then
    die "The PREFIX needs to be an absolute path" 1
fi

# Verify presence of DMD
dmd --help >& /dev/null || die "dmd not found on your \$PATH!" 1

# If uninstalling, do that now
if [ "$UNINSTALL" = "1" ]
then
    # Revert to Phobos if earlier evidence of existense is found
    # Only relevant for pre 0.99.3 installations
    if [ -e "$PREFIX/$LIB/libphobos.a.phobos" ]
    then
        mv     $PREFIX/$LIB/libphobos.a.phobos $PREFIX/$LIB/libphobos.a
    else
        if [ -e "$PREFIX/$LIB/libphobos.a" ]
        then
            rm -f $PREFIX/$LIB/libphobos.a
        fi
    fi
    if [ -e "$PREFIX/include/d/object.d.phobos" ]
    then
        mv     $PREFIX/include/d/object.d.phobos $PREFIX/include/d/object.d
    fi
    if [ -e "$PREFIX/$BIN/dmd.conf.phobos" ]
    then
        mv   $PREFIX/$BIN/dmd.conf $PREFIX/$BIN/dmd.conf.tango
        mv   $PREFIX/$BIN/dmd.conf.phobos $PREFIX/$BIN/dmd.conf
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
    # Since Tango 0.99
    if [ -e "$PREFIX/include/d/object.di" ]
    then
        rm -rf $PREFIX/include/d/tango
        rm -rf $PREFIX/include/d/std
        rm -f  $PREFIX/include/d/object.di
    fi

    # Prior to Tango 0.99.3
    if [ -e "$PREFIX/$LIB/libtango.a" ]
    then
		rm -f $PREFIX/$LIB/libtango.a
    fi

    # Since Tango 0.99.3
    if [ -e "$PREFIX/$LIB/libtango-base-dmd.a" ]
    then
        rm -f $PREFIX/$LIB/libtango-base-dmd.a
    fi

    if [ -e "$PREFIX/$LIB/libtango-user-dmd.a" ]
    then
        rm -f $PREFIX/$LIB/libtango-user-dmd.a
    fi

    die "Done!" 0
fi


# Verify that runtime was built
if [ ! -e libtango-base-dmd.a ]
then
    die "You must run build-dmd.sh before running install-dmd.sh" 4
fi

# Back up the original files
if [ -e "$PREFIX/include/d/object.d" ]
then
    mv -f $PREFIX/include/d/object.d $PREFIX/include/d/object.d.phobos
fi

# Create dmd.conf
create_dmd_conf() {
    cat > $PREFIX/$BIN/dmd.conf <<EOF
[Environment]
DFLAGS=-I$PREFIX/include/d -defaultlib=tango-base-dmd -debuglib=tango-base-dmd -version=Tango -version=Posix -L-L"$PREFIX/$LIB"
EOF
}

# Install ...
echo 'Copying files...'
mkdir -p $PREFIX/include/d || die "Failed to create include/d (maybe you need root privileges?)" 5
mkdir -p $PREFIX/$LIB/ || die "Failed to create $PREFIX/$LIB (maybe you need root privileges?)" 5
mkdir -p $PREFIX/$BIN/ || die "Failed to create $PREFIX/$BIN" 5
cp -pRvf libtango-base-dmd.a $PREFIX/$LIB/ || die "Failed to copy libraries" 7
cp -pRvf ../object.di $PREFIX/include/d/object.di || die "Failed to copy source" 8
if [ ! -e "$PREFIX/$BIN/dmd.conf" ]
then
    create_dmd_conf
else
    # Is it a phobos conf ?
    if [ ! "`grep '\-version=Tango' $PREFIX/$BIN/dmd.conf`" ]
    then
        mv $PREFIX/$BIN/dmd.conf $PREFIX/$BIN/dmd.conf.phobos
        create_dmd_conf
    else
        if [ ! "`grep '\-defaultlib=tango\-base\-dmd' $PREFIX/$BIN/dmd.conf`" ]
        then
            echo 'Appending -defaultlib switch to DFLAGS'
            sed -i.bak -e 's/^DFLAGS=.*$/& -defaultlib=tango-base-dmd/' $PREFIX/$BIN/dmd.conf
            if [ ! "`grep '\-debuglib=tango\-base\-dmd' $PREFIX/$BIN/dmd.conf`" ]
            then
                echo 'Appending -debuglib switch to DFLAGS'
                sed -i.bak -e 's/^DFLAGS=.*$/& -debuglib=tango-base-dmd/' $PREFIX/$BIN/dmd.conf
            fi
        else
            echo 'Found Tango enabled dmd.conf, assume it is working and leave it as is'
        fi
    fi
fi

# Verify installation
if [ "$VERIFY" = "1" ]
then
    echo 'Verifying installation.'
    if [ ! -e "$PREFIX/include/d/object.di" ]
    then
        die "object.di not properly installed to $PREFIX/include/d" 9
    fi
    if [ ! -e "$PREFIX/$LIB/libtango-base-dmd.a" ]
    then
        die "libtango-base-dmd.a not properly installed to $PREFIX/$LIB" 10
    fi
    if [ ! -e "$PREFIX/$BIN/dmd.conf" ]
    then
        die "dmd.conf not present in $PREFIX/$BIN" 11
    elif [ ! "`grep '\-version=Tango' $PREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf not Tango enabled" 12
    elif [ ! "`grep '\-defaultlib=tango\-base\-dmd' $PREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf don't have -defaultlib switch" 13
    elif [ ! "`grep '\-debuglib=tango\-base\-dmd' $PREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf don't have -debuglib switch" 14
    fi
    echo 'Installation OK.'
fi

die "Done!" 0
