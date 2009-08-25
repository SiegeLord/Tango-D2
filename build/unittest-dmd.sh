#!/usr/bin/env bash

# A simple script to build unittests for on posix for dmd
# Copyright (C) 2007  Lars Ivar Igesund, Fawzi Mohamed
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.


die() {
    echo "$1"
    exit $2
}

usage() {
    echo 'Usage: ./unittest-dmd.sh'
  exit 0
}

if [ -z "$DC" ] ; then
	DC=dmd
fi
LIB=
RUNALL=

compile() {
    DC=$1
    EXE=$2

    if ! which $DC >& /dev/null
    then
        echo "$DC not found on your \$PATH!"
    else
        cat > $EXE.d <<EOF
        module ${EXE};
EOF
        #for pkg in net time text util math core stdc ; do
            cd ../user
            find tango -name "*.d" | grep -v -i win32 | grep -v -i linux | grep -v "/\\." | sed -e"s/.d$/;/g" -e "sX/X.Xg" -e"s/^tango/import tango/g" >> ../build/$EXE.d
            cd ../build
        #done
        cat >> $EXE.d <<EOF
import tango.io.Stdout;
import tango.core.Runtime;
import tango.core.stacktrace.TraceExceptions;

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

	$DC -g -w -I../user -L-Llibs -L-ltango-user-dmd-tst -defaultlib=tango-base-dmd-tst -L-L$HOME/lib -L-ldl -L-lz -L-lbz2 -debug=UnitTest $EXE.d && rm $EXE.d

    fi

}

while [ "$#" != "0" ]
do
    case "$1" in
        --help)
            usage
            ;;
        *)
            usage
            ;;
    esac
    shift
done

compile $DC runUnitTest_dmd
