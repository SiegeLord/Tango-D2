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
  --prefix: Install to the specified prefix (absolute path), default is /usr/local
  --userlib: Installs libtango-user-dmd.a too. It will also be built if it is missing
                or older than libtango-base-dmd.a.
  --altconf: Use an alternate path component for the DMD conf, "bin" is default, "-" will
                set it to empty. See also --confprefix
  --altlib: Use an alternate path component for the library files, "lib" is default, "-" will
                set it to empty.
  --altincl: Use an alternate path component for import files, "include" is default, "-" will
                set it to empty (will install at PREFIX!)
  --confprefix: Use a specific prefix for where DMD binary resides, otherwise PREFIX is used
                (absolute path). Note that this combined with --altconf can be used to put
                dmd.conf somewhere else than together with the binary, either your $HOME or
                /etc. Note that together with the DMD binary seems most stable.
  --libprefix: Use a specific prefix for where libs should be installed, otherwise PREFIX is
                used (absolute path).
  --inclprefix: Use a specific prefix for where imports should be installed, otherwise
                PREFIX is used (absolute path).
  --uninstall: Uninstall Tango, switch back to standard Phobos.
  --as-phobos: This will install libtango-base-dmd.a as libphobos.a as per old style. This is
                default for older installations.
  --verify: Will verify installation.
  --help: Will print this help text.'
    exit 0
}

cd "`dirname $0`"

# Default values
UNINSTALL=0
VERIFY=0
ASPHOBOS=0
CONF="bin"
LIB="lib"
INCL="include"
PREFIX="/usr/local"
CONFPREFIX="$PREFIX"
LIBPREFIX="$PREFIX"
INCLPREFIX="$PREFIX"
BASELIB="libtango-base-dmd.a"

# 0) Parse arguments
if [ "$#" = "0" ]
then
    usage
fi

while [ "$#" != "0" ]
do

    case "$1" in
        --help)
            usage
            ;;
        --prefix)
            shift

            PREFIX="$1"
            CONFPREFIX="$PREFIX"
            LIBPREFIX="$PREFIX"
            INCLPREFIX="$PREFIX"
            ;;
        --altbin)
            shift

            if [ "$1" = "-" ]
            then
                BIN=""
            else
                BIN="$1"
            fi
            ;;
        --altlib)
            shift

            if [ "$1" = "-" ]
            then
                LIB=""
            else
                LIB="$1"
            fi
            ;;
        --altincl)
            shift

            if [ "$1" = "-" ]
            then
                INCL=""
            else
                INCL="$1"
            fi
            ;;
        --binprefix)
            shift
                CONFPREFIX="$1"
            ;;
        --libprefix)
            shift
                LIBPREFIX="$1"
            ;;
        --inclprefix)
            shift
                INCLPREFIX="$1"
            ;;
        --uninstall)
            UNINSTALL=1
            ;;
        --as-phobos)
            ASPHOBOS=1
            ;;
        --verify)
            VERIFY=1
            ;;
        --userlib)
            USERLIB=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Check if installed DMD supports -defaultlib flag, otherwise set ASPHOBOS
. dmdinclude

if [ ! "$DMDVERSIONMAJ" -gt "1" ]
then
    if [ ! "$DMDVERSIONMIN" -gt "21" ]
    then
        echo 'Your version of DMD have no support for -defaultlib flag, using libphobos.a'
        ASPHOBOS="1"
    fi
fi

if [ "$ASPHOBOS" = "1" ]
then
    BASELIB="libphobos.a"
    cp libtango-base-dmd.a libphobos.a
fi

echo "Binary prefix: $CONFPREFIX"
echo "Library prefix: $LIBPREFIX"
echo "Import prefix: $INCLPREFIX"

# Verify that PREFIX is absolute
if [ "${PREFIX:0:1}" != "/" ]
then
    die "PREFIX needs to be an absolute path, not $PREFIX" 1
elif [ "${CONFPREFIX:0:1}" != "/" ]
then
    die "CONFPREFIX needs to be an absolute path, not $CONFPREFIX" 1
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
        VERIFY=0
    fi

    # Revert to Phobos if earlier evidence of existense is found
    # Only relevant for pre 0.99.3 installations or --as-phobos installs
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
    if [ -e "$CONFPREFIX/$CONF/dmd.conf.phobos" ]
    then
        mv   $CONFPREFIX/$CONF/dmd.conf $CONFPREFIX/$CONF/dmd.conf.tango
        mv   $CONFPREFIX/$CONF/dmd.conf.phobos $CONFPREFIX/$CONF/dmd.conf
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

# Build missing libs
if [ ! -e libtango-base-dmd.a ]
then
    echo 'libtango-base-dmd.a not found, trying to build it.'
    ./build-dmd.sh || die "Failed to build libtango-base-dmd.a, try running build-dmd.sh 
manually." 4
fi

if [ "$USERLIB" = "1" ]
then
    if [ "$BASELIB" -nt "libtango-user-dmd.a" ]
    then
        echo 'libtango-user-dmd.a not found or older than libtango-base-dmd.a, trying to 
        build it.'
        ./build-tango.sh dmd || die "Failed to build libtango-user-dmd.a, try running 
        ./build-tango.sh dmd manually." 4
    fi
fi

# Back up the original files
if [ -e "$INCLPREFIX/$INCL/d/object.d" ]
then
    mv -f $INCLPREFIX/$INCL/d/object.d $INCLPREFIX/$INCL/d/object.d.phobos
fi

if [ "$ASPHOBOS" = "1" ]
then
    if [ -e "$LIBPREFIX/$LIB/libphobos.a" ]
    then
        mv -f $LIBPREFIX/$LIB/libphobos.a $LIBPREFIX/$LIB/libphobos.a.phobos
    fi
fi

# Create dmd.conf
create_dmd_conf() {
    if [ "$ASPHOBOS" = "0" ]
    then
        cat > $CONFPREFIX/$CONF/dmd.conf <<EOF
[Environment]
DFLAGS=-I$INCLPREFIX/$INCL/d -version=Tango -version=Posix -L-L"$LIBPREFIX/$LIB" 
EOF
    else
        cat > $CONFPREFIX/$CONF/dmd.conf <<EOF
[Environment]
DFLAGS=-I$INCLPREFIX/$INCL/d -defaultlib=tango-base-dmd -debuglib=tango-base-dmd -version=Tango -version=Posix -L-L"$LIBPREFIX/$LIB"
EOF
    fi
}

# Install ...
echo 'Copying files...'
mkdir -p $INCLPREFIX/$INCL/d || die "Failed to create $INCL/d (maybe you need root privileges?)" 5
mkdir -p $LIBPREFIX/$LIB/ || die "Failed to create $LIBPREFIX/$LIB (maybe you need root privileges?)" 5
mkdir -p $CONFPREFIX/$CONF/ || die "Failed to create $CONFPREFIX/$CONF" 5

cp -pRvf $BASELIB $LIBPREFIX/$LIB/ || die "Failed to copy base library." 7
cp -pRvf ../object.di $INCLPREFIX/$INCL/d/object.di || die "Failed to copy source." 8

if [ "$USERLIB" = "1" ]
then
    cp -pRvf libtango-user-dmd.a $LIBPREFIX/$LIB/ || die "Failed to copy user library." 8
fi

if [ ! -e "$CONFPREFIX/$CONF/dmd.conf" ]
then
    create_dmd_conf
else
    # Is it a phobos conf ?
    if [ ! "`grep '\-version=Tango' $CONFPREFIX/$CONF/dmd.conf`" ]
    then
        mv $CONFPREFIX/$CONF/dmd.conf $CONFPREFIX/$CONF/dmd.conf.phobos
        create_dmd_conf
    elif [ "$ASPHOBOS" = "1" ]
    then
        if [ "`grep '\-defaultlib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
        then
            rm -rf $CONFPREFIX/$CONF/dmd.conf
            create_dmd_conf
        fi
    else
        if [ ! "`grep '\-defaultlib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
        then
            echo 'Appending -defaultlib switch to DFLAGS'
            sed -i.bak -e 's/^DFLAGS=.*$/& -defaultlib=tango-base-dmd/' $CONFPREFIX/$CONF/dmd.conf
            if [ ! "`grep '\-debuglib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
            then
                echo 'Appending -debuglib switch to DFLAGS'
                sed -i.bak -e 's/^DFLAGS=.*$/& -debuglib=tango-base-dmd/' $CONFPREFIX/$CONF/dmd.conf
            fi
        else
            echo 'Found Tango enabled dmd.conf, assume it is working and leave it as is'
        fi
    fi
fi

if [ "$USERLIB" = "1" ]
then
    if [ ! "`grep '\-L\-ltango\-user\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
    then
        echo 'Appending user library to dmd.conf'
        sed -i.bak -e 's/^DFLAGS=.*$/& -L-ltango-user-dmd/' $CONFPREFIX/$CONF/dmd.conf
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
    if [ ! -e "$LIBPREFIX/$LIB/$BASELIB" ]
    then
        die "$BASELIB not properly installed to $LIBPREFIX/$LIB" 10
    fi
    if [ ! -e "$CONFPREFIX/$CONF/dmd.conf" ]
    then
        die "dmd.conf not present in $CONFPREFIX/$CONF" 11
    elif [ ! "`grep '\-version=Tango' $CONFPREFIX/$CONF/dmd.conf`" ]
    then
        die "dmd.conf not Tango enabled" 12
    elif [ ! "`grep '\-defaultlib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
    then
        die "dmd.conf don't have -defaultlib switch" 13
    elif [ ! "`grep '\-debuglib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
    then
        die "dmd.conf don't have -debuglib switch" 14
    fi
    if [ "$USERLIB" = "1" ]
    then
        if [ ! "`grep '\-L\-ltango\-user\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ] 
        then
            die "dmd.conf don't have reference to user library." 15
        elif [ ! -e "$LIBPREFIX/$LIB/libtango-user-dmd.a" ]
        then
            die "libtango-user-dmd.a not properly installed to $LIBPREFIX/$LIB" 16
        fi
    fi
    echo 'Installation OK.'
fi

die "Done!" 0
