#!/bin/bash

# A simple script to build libtango
# Copyright (C) 2007-2009  Lars Ivar Igesund
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.

die() {
    echo "$1"
    exit $2
}

DC=
LIB=

usage() {
    echo 'Usage: bob.sh <options> identifier
Example: build/script/bob.sh --user --runtime --verbose dmd
Options:
  --help: Will print this help text
  --noinline: Will turn off inlining
  --norelease: Drops optimzations
  --debug: Will enable debug info
  --warn: Will enable warnings
  --verbose: Increase verbosity 
  --user: Build user portion of library
  --runtime: Build runtime portion of library
  --libname <name>: The name that will be used for the built library (libtango.a is default)
  <identifier> is one of {dmd, gdc, ldc}

  Building just the user library is the default if nothing is specified.
    '
    exit 0
}

UNAME=`uname`
ARCH=""
INLINE="-inline"
POSIXFLAG=""
DEBUG=""
RELEASE="-release -O"
WARN=""
VERBOSE=0
USER=0
RUNTIME=0
LIBNAME="libtango.a"
GCC32=""
GCCRELEASE="-O3"

pushd `dirname $0`
# Compiler specific includes
. dmdinclude

# Checks for known compiler bugs
compilerbugs() {
    if [ "$DC" = "dmd" ]
    then
        dmdbugs
    fi
}

# Sets up settings for specific compiler versions
compilersettings() {
    if [ "$DC" = "dmd" ]
    then
        dmdsettings
    fi
}

# This filter can probably be improved quite a bit, but should work
# on the supported platforms as of April 2008
filter() {

    FILE=$1

    if [ "`echo $FILE | grep core.rt`" ]
    then
        if [ $RUNTIME == 0 ]
        then
            return 1
        fi
    else
        if [ $USER == 0 ]
        then
            return 1
        fi
    fi

    if [ "`echo $FILE | grep dmd`" -a ! "$DC" == "dmd" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep ldc`" -a ! "$DC" == "ldc" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep gdc`" -a ! "$DC" == "gdc" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep win32`" -o "`echo $FILE | grep Win32`" -o "`echo $FILE | grep windows`" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep darwin`" ]
    then
        if [ ! "$UNAME" == "Darwin" ]
        then
            return 1
        else
            return 0
        fi
    fi

    if [ "`echo $FILE | grep freebsd`" ]
    then
        if [ ! "$UNAME" == "FreeBSD" ]
        then
            return 1
        else
            return 0
        fi
    fi

    if [ "`echo $FILE | grep linux`" ]
    then
        if [ ! "$UNAME" == "Linux" ]
        then
            return 1
        fi
    fi

    return 0
}

# Compile the object files
compile() {
    FILENAME=$1
    OBJNAME=`echo $1 | sed -e 's/\.d//' | sed -e 's/\//\./g'`
    OBJNAME=${OBJNAME}.o

    if filter $OBJNAME 
    then
        if [ $VERBOSE == 1 ]; then echo "[$DC] $FILENAME"; fi
        $WRAPPER $ARCH $WARN -c $INLINE $DEBUG $RELEASE $POSIXFLAG -I. -Itango/core -Itango/core/vendor -version=Tango -of$OBJNAME $FILENAME
        if [ "$?" != 0 ]
        then
            return 1;
        fi
        ar -r $LIB $OBJNAME 2>&1 | grep -v "ranlib: .* has no symbols"
        rm $OBJNAME
    fi
}

compileGcc() {
    FILENAME=$1
    OBJNAME=`echo $1 | sed -e 's/\.c|\.S//' | sed -e 's/\//\./g'`
    OBJNAME=${OBJNAME}.o

    if filter $OBJNAME 
    then
        if [ $VERBOSE == 1 ]; then echo "[GCC] $FILENAME"; fi
        gcc -c $GCC32 $GCCRELEASE -o$OBJNAME $FILENAME
        if [ "$?" != 0 ]
        then
            return 1;
        fi
        ar -r $LIB $OBJNAME 2>&1 | grep -v "ranlib: .* has no symbols"
        rm $OBJNAME
    fi

}

# Build the libraries
build() {

    WRAPPER=$1
    LIB=$2
    
    echo Building $LIB

    if [ $RUNTIME == 0 -a $USER == 0 ]
    then
        RUNTIME=0
        USER=1
    fi

    if ! which $WRAPPER >& /dev/null
    then
        echo "$WRAPPER not found on your \$PATH!"
        return
    fi

    # Check if the compiler used has known bugs
    compilerbugs
    # Setup compiler specific settings
    compilersettings

    cd ../..

    if [ $VERBOSE = 1 ]
    then
        echo "D compiler call: $WRAPPER $ARCH $WARN -c $INLINE $DEBUG $RELEASE $POSIXFLAG -I. .Itango/core -Itango/core/vendor -version=Tango -of<object> <filename>"
    fi

    for file in `find tango -name '*.d'`
    do
        compile $file
        if [ "$?" = 1 ]
        then
            die "Compilation of $file failed" 1 
        fi
    done

    if [ $VERBOSE = 1 -a $RUNTIME = 1 ]
    then
        echo "C compiler call: gcc -c $GCC32 $GCCRELEASE -o<object> <filename>"
    fi

    for file in `find tango -name '*.c' -o -name '*.S'`
    do
        compileGcc $file
        if [ "$?" = 1 ]
        then
            die "Compilation of $file failed" 1 
        fi
    done

    ranlib $LIB 2>&1 | grep -v "ranlib: .* has no symbols"

    popd

    echo Built $LIB
}

if [ "$#" == "0" ]
then
    usage
fi

while [ "$#" != "0" ]
do
    case "$1" in
        --help)
            usage
            ;;
        --warn)
            WARN="-w"
            ;;
        --debug)
            DEBUG="-g -debug"
            ;;
        --norelease)
            RELEASE=""
            ;;
        --noinline)
            INLINE=""
            ;;
        --verbose) 
            VERBOSE=1
            ;;
        --user)
            USER=1
            ;;
        --runtime)
            RUNTIME=1
            ;;
        --libname)
            shift
            LIBNAME=$1
            ;;
        dmd)
            DC="dmd"
            build dmd $LIBNAME
            ;;
        gdc)
            DC="gdc"
            POSIXFLAG="-version=Posix"
            build gdmd $LIBNAME
            ;;
        ldc)
            DC="ldc"
            build ldmd $LIBNAME
            ;;
        *)
            usage
            ;;
    esac
    shift
done
