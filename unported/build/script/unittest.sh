#!/usr/bin/env bash

# Script to build and run all the Tango unittests on a Posix platform.
# Copyright (C) 2007-2010  Lars Ivar Igesund
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.

EXE=runUnittests_$DC
DL="-L-ldl " 
UNAME=`uname`
OPTIONS="-debug -gc -debug=utf -debug=UnitTest" #  :w -debug=PRINTF"

error () {
    echo "Example : DC=dmd PLATFORM=linux ARCH=32 build/script/unittest.sh"
    exit 1
}

if [ ! "$DC" ]
then
    echo "Set DC to the name of your compiler, e.g. dmd or ldc"
    error
fi

if [ ! "$ARCH" -o ! "$PLATFORM" ]
then
    echo "Set PLATFORM to name of your OS and ARCH to architecture, e.g. 64"
    error
fi

if [ $DC == "ldc" ]
then
    OPTIONS="-oq -d-debug -d-debug=UnitTest -gc"
    DL="-L-ldl "
fi

if [ $DC == "gdc" ]
then
    OPTIONS="-fdebug -fdebug=UnitTest -funittest -g -nophoboslib"
    DL="-ldl -L.  -ltango-$DC-tst -lz -lbz2 -o $EXE"
fi

echo build/bin/${PLATFORM}32/bob -r=$DC -m=$ARCH -c=$DC -p=$PLATFORM -l=libtango-$DC-tst -o=\"-m$ARCH -unittest $OPTIONS\" . 
build/bin/${PLATFORM}32/bob -r=$DC -m=$ARCH -c=$DC -p=$PLATFORM -l=libtango-$DC-tst -o="-m$ARCH -unittest $OPTIONS" . 


echo "Compiled Library"

if ! which $DC >& /dev/null
then
    echo "$DC not found on your \$PATH!"
    exit 1
fi

cat > $EXE.d <<EOF
module ${EXE};

EOF

DFILES=""
for f in `find tango -name "*.d" | grep -v tango.core.rt | grep -v tango.core.vendor | grep -v -i win32`
do
    DFILES="$DFILES $f"
    echo $f | sed -e"s/.d$/;/g" -e "sX/X.Xg" -e"s/^tango/import tango/g" >> $EXE.d
done

cat >> $EXE.d <<EOF

import tango.io.Stdout;
import tango.core.Runtime;
import tango.core.tools.TraceExceptions;

import tango.stdc.stdio : printf;

bool tangoUnitTester()
{
    uint countFailed = 0;
    uint countTotal = 1;
    
    Stdout ("NOTE: This is still fairly rudimentary, and will only report the").newline;
    Stdout ("    first error per module.").newline;
    foreach ( m; ModuleInfo )  // _moduleinfo_array )
    {
        if ( m.unitTest) {
            Stdout.format ("{}. Executing unittests in '{}' ", countTotal, m.name).flush;
            countTotal++;
            try {
               m.unitTest();
            }
            catch (Exception e) {
                countFailed++;
                Stdout(" - Unittest failed.").newline;
                e.writeOut(delegate void(char[]s){ Stdout(s); });
                continue;
            }
            Stdout(" - Success.").newline;
        }
    }

    Stdout.format ("{} out of {} tests failed.", countFailed, countTotal - 1).newline;
    return true;
}

static this() {
    Runtime.moduleUnitTester( &tangoUnitTester );
}

void main() { } // assert ( 0 == 1, "Main .. "); }
EOF

if [ "$UNAME" == "FreeBSD" ]
then
    DL=""
fi

echo "$DC $EXE.d $DFILES $OPTIONS -m$ARCH -unittest -L-L. -L-ltango-$DC-tst  $DL -L-lz -L-lbz2"
$DC $EXE.d $DFILES $OPTIONS -m$ARCH -Itango/core/vendor -unittest -L-L. -L-ltango-$DC-tst  $DL -L-lz -L-lbz2  #&& rm $EXE.d && rm libtango-$DC-tst.a

./runUnittests_$DC




