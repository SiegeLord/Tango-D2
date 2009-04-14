#!/usr/bin/env bash

# A simple script to build unittests for on posix for dmd/gdc
# Copyright (C) 2007  Lars Ivar Igesund
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.


die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: ./unittest.sh [otions ...]
Options:
  --help: This message
  --run-all: Reports result instead of breaking. Do not use this if you want to
         run unittest runner through a debugger.
  dmd:    Builds unittests for dmd
  gdc:    Builds unittests for gdc
  ldc: Builds unittests for ldc

  <none>: Builds unittests for all known compilers.'
  exit 0
}

DC=
LIB=
RUNALL=

compile() {

    DC=$1
    EXE=$2

    rebuild --help >& /dev/null || die "rebuild required, aborting" 1

    if ! which $DC >& /dev/null
    then
        echo "$DC not found on your \$PATH!"
    else
        cd ..
        cat > $EXE.d <<EOF
        module ${EXE};
EOF
        #for pkg in net time text util math core stdc ; do
            find tango -name "*.d" | grep -v -i win32 | grep -v "/\\." | sed -e"s/.d$/;/g" -e "sX/X.Xg" -e"s/^tango/import tango/g" >> $EXE.d
        #done
        cat >> $EXE.d <<EOF
import tango.io.Stdout;
import tango.core.Runtime;

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

void main() {}
EOF

        rebuild -w -d -g -L-ldl -L-lz -L-lbz2 -debug=UnitTest -debug -full -clean -unittest \
        -version=UnitTest $EXE.d

        mv $EXE lib/$EXE
        rm $EXE.d

        cd lib/
    fi

}

while [ "$#" != "0" ]
do
    case "$1" in
        --help)
            usage
            ;;
        --run-all)
            ;;
        dmd)
            DMD=1
            ;;
        gdc)
            GDC=1
            ;;
        ldc)
            LDC=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

if [ ! "$DMD" -a ! "$GDC" -a ! "$LDC" ]
then
    DMD=1
    GDC=1
    LDC=1
fi

if [ "$DMD" = "1" ]
then
    compile dmd runUnitTest_dmd
fi
if [ "$GDC" = "1" ]
then
    compile gdc runUnitTest_gdc
fi
if [ "$LDC" = "1" ]
then
    compile ldc runUnitTest_ldc
fi
