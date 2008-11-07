#!/bin/bash

# Script to install Tango on *nix based platforms
# Copyright (C) 2006-2008  Gregor Richards, Lars Ivar Igesund
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.
#
# Modifications by Alexander Panek

die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: install.sh [[option <argument>] ...] <compilername> 
Options:
  --prefix: Install to the specified prefix (absolute path), default is /usr/local
  --userlib: Installs libtango-user-*.a too. It will also be built if it is missing
                or older than libtango-base-*.a. Note that this is not necessary if
                you use DSSS or other build tools for the user part of the Tango API
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
  --as-phobos: This will install libtango-base-*.a as lib*phobos.a as per old style. This is
                default for older DMD installations.
  --verify: Will verify installation.
  --verbose: Will produce various progress output
  --help: Will print this help text.'
    exit 0
}

INSTALLED=0
BASELIB64=0
PREFIX=
VERBOSE=0
USERPREFIX=0
VERIFY=0

# Default values
defaultdmd() {
    UNINSTALL=0
    ASPHOBOS=0
    CONF="bin"
    LIB="lib"
    INCL="include"
    if [ "$USERPREFIX" = "0" ]
    then
        PREFIX="/usr/local"
    fi
    CONFPREFIX="$PREFIX"
    LIBPREFIX="$PREFIX"
    INCLPREFIX="$PREFIX"
    BASELIBNAME="libtango-base-dmd.a"
    USERLIBNAME="libtango-user-dmd.a"
}

defaultgdc() {
    UNINSTALL=0
    ASPHOBOS=1 # Using libgphobos name for now
    CONF="bin"
    LIB="lib"
    INCL="include"

    if [ "$USERPREFIX" = "0" ]
    then
        LIBPREFIX="`${CROSS}gdc -print-file-name=libgphobos.a`"
        LIBPREFIX="`readlink -f $LIBPREFIX`"
        LIBPREFIX="`dirname $LIBPREFIX`/.."

        # If we have which, use it to get the prefix
        which ${CROSS}gdc >& /dev/null
        if [ "$?" = "0" ]
        then
            PREFIX="`which ${CROSS}gdc`"
            PREFIX="`dirname $PREFIX`/.."
        else
            PREFIX="$LIBPREFIX"
        fi

        if [ -e "$LIB_PREFIX/lib64" ]
        then
            BASELIB64=1
        fi
    else
        LIBPREFIX="$PREFIX"
    fi

    CONFPREFIX="$PREFIX"
    INCLPREFIX="$PREFIX"
    BASELIBNAME="libgphobos.a"
    USERLIBNAME="libgtango.a"
}

uninstalldmd() {
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
}

uninstallgdc() {
    rm -rf $LIBPREFIX/$LIB/libgphobos.a $PREFIX/include/d/$GDC_VER/object.d
    if [ "$BASELIB_64" = "1" ]
    then
        rm -rf $LIBPREFIX/lib64/libgphobos.a
        if [ -e "$LIBPREFIX/lib64/libgphobos.a.phobos" ]
        then
            mv $LIBPREFIX/lib64/libgphobos.a.phobos $LIBPREFIX/lib64/libgphobos.a
        fi
    fi
    if [ -e "$LIBPREFIX/$LIB/libgphobos.a.phobos" ]
    then
        mv $PREFIX/include/d/$GDC_VER/object.d.phobos $PREFIX/include/d/$GDC_VER/object.d
        mv $LIBPREFIX/$LIB/libgphobos.a.phobos $LIBPREFIX/$LIB/libgphobos.a
    fi
}

backupdmd() {
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
}

backupgdc() {
    if [ -e "$LIBPREFIX/$LIB/libgphobos.a" -a \
         ! -e "$LIBPREFIX/$LIB/libgphobos.a.phobos" ]
    then
        if [ "$VERBOSE" = "1" ]; then echo "Backing up libgphobos.a to libgphobos.a.phobos"; fi
        mv -f $LIBPREFIX/$LIB/libgphobos.a $LIBPREFIX/$LIB/libgphobos.a.phobos
        mv -f $PREFIX/include/d/$GDC_VER/object.d $PREFIX/include/d/$GDC_VER/object.d.phobos
        if [ "$BASELIB_64" = "1" ]
        then
            if [ -e "$LIBPREFIX/lib64/libgphobos.a" ]
            then
                mv -f $LIBPREFIX/lib64/libgphobos.a $LIBPREFIX/lib64/libgphobos.a.phobos
            fi
        fi
    fi
}

dmdtest() {
    if [ "$DMDVERSIONMAJ" != "" ]
    then
        if [ ! "$DMDVERSIONMAJ" -gt 1 ]
        then
            if [ ! "$DMDVERSIONMIN" -gt 21 ]
            then
                if [ "$VERBOSE" = "1" ]; then echo "Your version of DMD have no support for -defaultlib flag, using libphobos.a"; fi
                ASPHOBOS="1"
            fi
        fi
    fi

    return 0
}

gdctest() {
    # TODO Should test for GDC version since GDC 0.24 and older really isn't usable anymore
    return 0
}

# Create dmd.conf
create_dmd_conf() {
    if [ "$ASPHOBOS" = "1" ]
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

configdmd() {
    if [ ! -e "$CONFPREFIX/$CONF/dmd.conf" ]
    then
        if [ "$VERBOSE" = "1" ]; then echo "Could not find dmd.conf in $CONFPREFIX/$CONF, create a new one."; fi
        create_dmd_conf
    else
        # Is it a phobos conf ?
        if [ ! "`grep '\-version=Tango' $CONFPREFIX/$CONF/dmd.conf`" ]
        then
            if [ "$VERBOSE" = "1" ]; then echo "Backing up dmd.conf to dmd.conf.phobos, creating new dmd.conf"; fi
            mv $CONFPREFIX/$CONF/dmd.conf $CONFPREFIX/$CONF/dmd.conf.phobos
            create_dmd_conf
        elif [ "$ASPHOBOS" = "1" ]
        then
            if [ "`grep '\-defaultlib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
            then
                if [ "$VERBOSE" = "1" ]; then echo "Removing and re-creating dmd.conf"; fi
                rm -rf $CONFPREFIX/$CONF/dmd.conf
                create_dmd_conf
            fi
        else
            if [ ! "`grep '\-defaultlib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
            then
                if [ "$VERBOSE" = "1" ]; then echo "Appending -defaultlib switch to DFLAGS"; fi
                sed -i.bak -e 's/^DFLAGS=.*$/& -defaultlib=tango-base-dmd/' $CONFPREFIX/$CONF/dmd.conf
                if [ ! "`grep '\-debuglib=tango\-base\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
                then
                    if [ "$VERBOSE" = "1" ]; then echo "Appending -debuglib switch to DFLAGS"; fi
                    sed -i.bak -e 's/^DFLAGS=.*$/& -debuglib=tango-base-dmd/' $CONFPREFIX/$CONF/dmd.conf
                fi
            else
                if [ "$VERBOSE" = "1" ]; then echo "Found Tango enabled dmd.conf, assume it is working and leave it as is"; fi
            fi
        fi
    fi

    if [ "$USERLIB" = "1" ]
    then
        if [ ! "`grep '\-L\-ltango\-user\-dmd' $CONFPREFIX/$CONF/dmd.conf`" ]
        then
            if [ "$VERBOSE" = "1" ]; then echo "Appending user library to dmd.conf"; fi
            sed -i.bak -e 's/^DFLAGS=.*$/& -L-ltango-user-dmd/' $CONFPREFIX/$CONF/dmd.conf
        fi
    fi

}

configgdc() {
    # Implement if it makes sense to use GDC spec file (from GDC 0.25?) as we use dmd.conf
    return 0
}

verifydmd() {
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
}

verifygdc() {
    return 0
}

verify() {
    if [ "$VERBOSE" = "1" ]; then echo "Verifying installation."; fi
    if [ ! -e "$INCLPREFIX/$INCL/d/object.di" ]
    then
        die "object.di not properly installed to $INCLPREFIX/$INCL/d" 9
    fi
    if [ ! -e "$LIBPREFIX/$LIB/$BASELIB" ]
    then
        die "$BASELIB not properly installed to $LIBPREFIX/$LIB" 10
    fi
    if [ "$VERBOSE" = "1" ]; then echo "Installation OK."; fi
}

install() {
    if [ "$INSTALLED" = "1" ]
    then
        die "Installation is supported for only one compiler per run.", 30
    fi
    INSTALLED=1

    default$1
    . $1include

    if [ "$VERBOSE" = "1" ]; then echo "Prefix was set to $PREFIX"; fi

    if $1test
    then
        if [ "$1" = "dmd" ]
        then
            if [ "$ASPHOBOS" = "1" ]
            then
                BASELIB="libphobos.a"
                if [ "$VERBOSE" = "1" ]
                then 
                    echo "Copy libtango-base-dmd.a to libphobos.a"
                    cp -pv libtango-base-dmd.a libphobos.a
                else
                    cp -p libtango-base-dmd.a libphobos.a
                fi
            fi
        fi

        if [ "$VERBOSE" = "1" ]
        then
            echo "Binary prefix: $CONFPREFIX"
            echo "Library prefix: $LIBPREFIX"
            echo "Import prefix: $INCLPREFIX"
        fi

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

        # Verify presence of compiler
        $1 --help >& /dev/null || die "$1 not found on your \$PATH!" 1

        # If uninstalling, do that now
        if [ "$UNINSTALL" = "1" ]
        then
            if [ "$VERIFY" = "1" ]
            then
                if [ "$VERBOSE" = "1" ]; then echo "Not veryfying uninstall"; fi
                VERIFY=0
            fi

            uninstall$1
            if [ "$VERBOSE" = "1" ]; then echo "Uninstall complete!"; fi
            exit 0
        fi

        # Build missing libs
        if [ ! -e $BASELIBNAME ]
        then
            if [ "$VERBOSE" = "1" ]; then echo "$BASELIBNAME not found, trying to build it."; fi
            ./build-$1.sh || die "Failed to build $BASELIBNAME, try running build-$1.sh manually." 4
        fi

        if [ "$USERLIB" = "1" ]
        then
            if [ "$BASELIBNAME" -nt "$USERLIBNAME" ]
            then
                if [ "$VERBOSE" = "1" ]
                then 
                    echo "$USERLIBNAME not found or older than $BASELIBNAME, trying to build it."
                    ./build-tango.sh --verbose $1 || die "Failed to build $USERLIBNAME, try running ./build-tango.sh $1 manually." 4
                else
                    ./build-tango.sh $1 || die "Failed to build $USERLIBNAME, try running ./build-tango.sh $1 manually." 4
                fi
            fi
        fi

        backup$1
        if [ "$VERBOSE" = "1" ]
        then
            echo "Copying files..."
            echo "Creating directories $INCLPREFIX/$INCL/d, $LIBPREFIX/$LIB and $CONFPREFIX/$CONF"
            echo "  if they don't exist."
            mkdir -pv $INCLPREFIX/$INCL/d || die "Failed to create $INCL/d (maybe you need root privileges?)" 5
            mkdir -pv $LIBPREFIX/$LIB/ || die "Failed to create $LIBPREFIX/$LIB (maybe you need root privileges?)" 5
            mkdir -pv $CONFPREFIX/$CONF/ || die "Failed to create $CONFPREFIX/$CONF" 5
            echo "Installing $BASELIBNAME to $LIBPREFIX/$LIB"
            cp -pRvf $BASELIBNAME $LIBPREFIX/$LIB/ || die "Failed to copy base library." 7
            echo "Installing object.di to $INCLPREFIX/$INCL/d/"
            cp -pRvf ../object.di $INCLPREFIX/$INCL/d/object.di || die "Failed to copy source." 8
        else
            mkdir -p $INCLPREFIX/$INCL/d || die "Failed to create $INCL/d (maybe you need root privileges?)" 5
            mkdir -p $LIBPREFIX/$LIB/ || die "Failed to create $LIBPREFIX/$LIB (maybe you need root privileges?)" 5
            mkdir -p $CONFPREFIX/$CONF/ || die "Failed to create $CONFPREFIX/$CONF" 5
            cp -pRf $BASELIBNAME $LIBPREFIX/$LIB/ || die "Failed to copy base library." 7
            cp -pRf ../object.di $INCLPREFIX/$INCL/d/object.di || die "Failed to copy source." 8
        fi

        if [ "$USERLIB" = "1" ]
        then
            if [ "$VERBOSE" = "1" ]
            then 
                echo "Installing $USERLIBNAME to $LIBPREFIX/$LIB"
                cp -pRvf $USERLIBNAME $LIBPREFIX/$LIB/ || die "Failed to copy user library." 8
            else
                cp -pRf $USERLIBNAME $LIBPREFIX/$LIB/ || die "Failed to copy user library." 8
            fi
            cd ..
            if [ "$VERBOSE" = "1" ]; then echo "Installing import files to $INCLPREFIX/$INCL/d/"; fi
            for file in `find tango -name '*.di' -o -name '*.d'`
            do
                if [ ! -e `dirname $INCLPREFIX/$INCL/d/$file` ]
                then
                    if [ "$VERBOSE" = "1" ]; then mkdir -pv `dirname $INCLPREFIX/$INCL/d/$file`;
                    else mkdir -p `dirname $INCLPREFIX/$INCL/d/$file`; fi
                fi
                if [ "$VERBOSE" = "1" ]; then cp $file -pRvf $INCLPREFIX/$INCL/d/$file;
                else cp $file -pRf $INCLPREFIX/$INCL/d/$file; fi
            done
        fi

        config$1

        # Verify installation
        if [ "$VERIFY" = "1" ]
        then
            verify
            verify$1
        fi

    fi

    if [ "$VERBOSE" = "1" ]; then echo "Done installing Tango for $1!"; fi 
    exit 0
}

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
            USERPREFIX=1
            ;;
        --altconf)
            shift

            if [ "$1" = "-" ]
            then
                CONF=""
            else
                CONF="$1"
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
        --confprefix)
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
        --verbose)
            VERBOSE=1
            ;;
        dmd)
            install dmd
            ;;
        gdc)
            install gdc
            ;;
        *)
            usage
            ;;
    esac
    shift
done

