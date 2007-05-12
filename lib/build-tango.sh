#!/bin/bash +x

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

# This filter can probably be improved quite a bit, but should work
# on the supported platforms as of May 2007
filter() {

    FILE=$1
    if [ "`echo $FILE | grep win32`" -o "`echo $FILE | grep Win32`" ]
    then
        return 1
    fi

    if [ "`echo $FILE | grep darwin`" ]
    then
        if [ `uname` == Linux ]
        then
            return 1
        else
            return 0
        fi
    fi

    if [ "`echo $FILE | grep linux`" ]
    then
        if [ ! `uname` == Linux ]
        then
            return 1
        fi
    fi

    return 0
}

compile() {
    FILENAME=$1
    OBJNAME=`echo $1 | sed -e 's/\.d//' | sed -e 's/\//\./g'`
    OBJNAME=${OBJNAME}.o

    if filter $OBJNAME
    then
        $DC -c -inline -release -O -version=Posix -version=Tango -of$OBJNAME $FILENAME
        ar -r lib/$LIB $OBJNAME
        rm $OBJNAME
    fi
}

build() {

    DC=$1
    LIB=$2

    if ! $DC --help >& /dev/null
    then
        echo "$DC not found on your \$PATH!"
    else

        cd ..

        for file in `find tango -name '*.d'`
        do
            compile $file
        done

        ranlib lib/$LIB

        cd lib
    fi
}

build dmd libtango.a
build gdmd libgtango.a
