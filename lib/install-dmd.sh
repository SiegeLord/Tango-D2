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
    echo 'Usage: install-dmd.sh [option <argument>] ... 
Options:
  --prefix: Install to the specified prefix (absolute path).
  --altbin: Use an alternate path component for the DMD binary, "bin" is default, "-" will
                set it to empty.
  --altlib: Use an alternate path component for the library files, "lib" is default, "-" will
                set it to empty.
  --altincl: Use an alternate path component for import files, "include" is default, "-" will
                set it to empty (will install at PREFIX!)
  --binprefix: Use a specific prefix for where DMD binary resides, otherwise PREFIX is used
                (absolute path).
  --libprefix: Use a specific prefix for where libs should be installed, otherwise PREFIX is
                used (absolute path).
  --inclprefix: Use a specific prefix for where imports should be installed, otherwise
                PREFIX is used (absolute path).
  --uninstall: Uninstall Tango, switch back to standard Phobos.
  --verify: Will verify installation.
  --help: Will print this help text.'
    exit 0
}

cd "`dirname $0`"

# Default values
UNINSTALL=0
VERIFY=0
BIN="bin"
LIB="lib"
INCL="include"
PREFIX="/usr/local"
BINPREFIX="$PREFIX"
LIBPREFIX="$PREFIX"
INCLPREFIX="$PREFIX"

# 0) Parse arguments
if [ "$#" = "0" ]
then
    usage
fi

while [ "$#" != "0" ]
do
    if [ "$1" = "--help" ]
    then
        usage
    fi
    if [ "$1" = "--prefix" ]
    then
        shift

        PREFIX="$1"
        BINPREFIX="$PREFIX"
        LIBPREFIX="$PREFIX"
        INCLPREFIX="$PREFIX"
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
    elif [ "$1" = "--altincl" ]
    then
        shift

        if [ "$1" = "-" ]
        then
            INCL=""
        else
            INCL="$1"
        fi
    elif [ "$1" = "--binprefix" ]
    then
        shift
            BINPREFIX="$1"

    elif [ "$1" = "--libprefix" ]
    then
        shift
            LIBPREFIX="$1"

    elif [ "$1" = "--inclprefix" ]
    then
        shift
            INCLPREFIX="$1"

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

echo "Binary prefix: $BINPREFIX"
echo "Library prefix: $LIBPREFIX"
echo "Import prefix: $INCLPREFIX"

# Verify that PREFIX is absolute
if [ "${PREFIX:0:1}" != "/" ]
then
    die "PREFIX needs to be an absolute path, not $PREFIX" 1
elif [ "${BINPREFIX:0:1}" != "/" ]
then
    die "BINPREFIX needs to be an absolute path, not $BINPREFIX" 1
elif [ "${LIBPREFIX:0:1}" != "/" ]
then
    die "LIB needs to be an absolute path, not $LIBPREFIX" 1
elif [ "${INCLPREFIX:0:1}" != "/" ]
then
    die "INCLPREFIX needs to be an absolute path, not $INCLPREFIX" 1
fi

# Verify presence of DMD
dmd --help >& /dev/null || die "dmd not found on your \$PATH!" 1

# If uninstalling, do that now
if [ "$UNINSTALL" = "1" ]
then
    if [ "$VERIFY" = "1" ]
    then
        echo "Not veryfying uninstall."
        VERIFY="0"
    fi

    # Revert to Phobos if earlier evidence of existense is found
    # Only relevant for pre 0.99.3 installations
    if [ -e "$LIBPREFIX/$LIB/libphobos.a.phobos" ]
    then
        mv     $LIBPREFIX/$LIB/libphobos.a.phobos $LIBPREFIX/$LIB/libphobos.a
    else
        if [ -e "$LIBPREFIX/$LIB/libphobos.a" ]
        then
            rm -f $LIBPREFIX/$LIB/libphobos.a
        fi
    fi
    if [ -e "$INCLPREFIX/$INCL/d/object.d.phobos" ]
    then
        mv     $INCLPREFIX/$INCL/d/object.d.phobos $INCLPREFIX/$INCL/d/object.d
    fi
    if [ -e "$BINPREFIX/$BIN/dmd.conf.phobos" ]
    then
        mv   $BINPREFIX/$BIN/dmd.conf $BINPREFIX/$BIN/dmd.conf.tango
        mv   $BINPREFIX/$BIN/dmd.conf.phobos $BINPREFIX/$BIN/dmd.conf
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
    if [ -e "$INCLPREFIX/$INCL/d/object.di" ]
    then
        rm -rf $INCLPREFIX/$INCL/d/tango
        rm -rf $INCLPREFIX/$INCL/d/std
        rm -f  $INCLPREFIX/$INCL/d/object.di
    fi

    # Prior to Tango 0.99.3
    if [ -e "$PREFIX/$LIB/libtango.a" ]
    then
		rm -f $PREFIX/$LIB/libtango.a
    fi

    # Since Tango 0.99.3
    if [ -e "$LIBPREFIX/$LIB/libtango-base-dmd.a" ]
    then
        rm -f $LIBPREFIX/$LIB/libtango-base-dmd.a
    fi

    if [ -e "$LIBPREFIX/$LIB/libtango-user-dmd.a" ]
    then
        rm -f $LIBPREFIX/$LIB/libtango-user-dmd.a
    fi

    die "Done!" 0
fi

# Verify that runtime was built
if [ ! -e libtango-base-dmd.a ]
then
    die "You must run build-dmd.sh before running install-dmd.sh" 4
fi

# Back up the original files
if [ -e "$INCLPREFIX/$INCL/d/object.d" ]
then
    mv -f $INCLPREFIX/$INCL/d/object.d $INCLPREFIX/$INCL/d/object.d.phobos
fi

# Create dmd.conf
create_dmd_conf() {
    cat > $BINPREFIX/$BIN/dmd.conf <<EOF
[Environment]
DFLAGS=-I$INCLPREFIX/$INCL/d -defaultlib=tango-base-dmd -debuglib=tango-base-dmd -version=Tango -version=Posix -L-L"$LIBPREFIX/$LIB"
EOF
}

# Install ...
echo 'Copying files...'
mkdir -p $INCLPREFIX/$INCL/d || die "Failed to create $INCL/d (maybe you need root privileges?)" 5
mkdir -p $LIBPREFIX/$LIB/ || die "Failed to create $LIBPREFIX/$LIB (maybe you need root privileges?)" 5
mkdir -p $BINPREFIX/$BIN/ || die "Failed to create $BINPREFIX/$BIN" 5
cp -pRvf libtango-base-dmd.a $LIBPREFIX/$LIB/ || die "Failed to copy libraries" 7
cp -pRvf ../object.di $INCLPREFIX/$INCL/d/object.di || die "Failed to copy source" 8
if [ ! -e "$BINPREFIX/$BIN/dmd.conf" ]
then
    create_dmd_conf
else
    # Is it a phobos conf ?
    if [ ! "`grep '\-version=Tango' $BINPREFIX/$BIN/dmd.conf`" ]
    then
        mv $BINPREFIX/$BIN/dmd.conf $BINPREFIX/$BIN/dmd.conf.phobos
        create_dmd_conf
    else
        if [ ! "`grep '\-defaultlib=tango\-base\-dmd' $BINPREFIX/$BIN/dmd.conf`" ]
        then
            echo 'Appending -defaultlib switch to DFLAGS'
            sed -i.bak -e 's/^DFLAGS=.*$/& -defaultlib=tango-base-dmd/' $BINPREFIX/$BIN/dmd.conf
            if [ ! "`grep '\-debuglib=tango\-base\-dmd' $BINPREFIX/$BIN/dmd.conf`" ]
            then
                echo 'Appending -debuglib switch to DFLAGS'
                sed -i.bak -e 's/^DFLAGS=.*$/& -debuglib=tango-base-dmd/' $BINPREFIX/$BIN/dmd.conf
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
    if [ ! -e "$INCLPREFIX/$INCL/d/object.di" ]
    then
        die "object.di not properly installed to $INCLPREFIX/$INCL/d" 9
    fi
    if [ ! -e "$LIBPREFIX/$LIB/libtango-base-dmd.a" ]
    then
        die "libtango-base-dmd.a not properly installed to $LIBPREFIX/$LIB" 10
    fi
    if [ ! -e "$BINPREFIX/$BIN/dmd.conf" ]
    then
        die "dmd.conf not present in $BINPREFIX/$BIN" 11
    elif [ ! "`grep '\-version=Tango' $BINPREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf not Tango enabled" 12
    elif [ ! "`grep '\-defaultlib=tango\-base\-dmd' $BINPREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf don't have -defaultlib switch" 13
    elif [ ! "`grep '\-debuglib=tango\-base\-dmd' $BINPREFIX/$BIN/dmd.conf`" ]
    then
        die "dmd.conf don't have -debuglib switch" 14
    fi
    echo 'Installation OK.'
fi

die "Done!" 0
