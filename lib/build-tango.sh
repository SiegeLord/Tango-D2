#!/usr/bin/env bash

# A simple script to build libtango.a/libgtango
# Copyright (C) 2007  Lars Ivar Igesund
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
    echo 'Usage: build-tango.sh <options> identifier
Options:
  --help: Will print this help text
  --warn: Will enable warnings
  --verbose: Increase verbosity 
  <identifier> is one of {dmd, gdc, mac} and will build libtango.a,
                libgtango.a or universal Mac binaries respectively

  The script must be called from within lib/ and the resulting
  binaries will be found there. The build requires that libtango-base-dmd.a/
  libgphobos.a already was built.'
    exit 0
}

UNAME=`uname`
INLINE="-inline"
WARN=""
VERBOSE=0

# Compiler specific includes
. dmdinclude

# Checks for known compiler bugs
compilerbugs() {
    if [ "$DC" = "dmd" ]
    then
        dmdbugs
    fi
}

# This filter can probably be improved quite a bit, but should work
# on the supported platforms as of April 2008
filter() {

    FILE=$1
    if [ "`echo $FILE | grep group`" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep win32`" -o "`echo $FILE | grep Win32`" ]
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
        $DC $WARN -c $INLINE -release -O -version=Posix -version=Tango -of$OBJNAME $FILENAME
        ar -r lib/$LIB $OBJNAME 2>&1 | grep -v "ranlib: .* has no symbols"
        rm $OBJNAME
    fi
}

# Build the libraries
build() {

    DC=$1
    LIB=$2

    if ! $DC --help >& /dev/null
    then
        echo "$DC not found on your \$PATH!"
        return
    fi

    # Check if the compiler used has known bugs
    compilerbugs

    if [ ! -e "$3" ]
    then
        die "Dependency $3 not present, run build-yourcompiler.sh first" 1
    fi

    cd ..

    for file in `find tango -name '*.d'`
    do
        compile $file
    done

    ranlib lib/$LIB 2>&1 | grep -v "ranlib: .* has no symbols"

    cd lib
}

ORIGDIR=`pwd`
if [ ! "`basename $ORIGDIR`" = "lib" ]
then
    die "You must run this script from the lib directory." 1
fi

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
        --verbose) 
            VERBOSE=1
            ;;
        dmd)
            build dmd libtango-user-dmd.a libtango-base-dmd.a
            ;;
        gdc)
            build gdmd libgtango.a libgphobos.a
            ;;
        mac)
            # build Universal Binary version of the Tango library
            build powerpc-apple-darwin8-gdmd libgtango.a.ppc libgphobos.a.ppc
            build i686-apple-darwin8-gdmd libgtango.a.i386 libgphobos.a.i386
            lipo -create -output libgtango.a libgtango.a.ppc libgtango.a.i386
            ;;
        *)
            usage
            ;;
    esac
    shift
done
