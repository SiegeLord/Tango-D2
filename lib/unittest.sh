#!/bin/bash +x

# A simple script to build unittests for on posix for dmd/gdc
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

compile() {

    DC=$1
    EXE=$2

    rebuild --help >& /dev/null || die "rebuild required, aborting" 1

    if ! $DC --help >& /dev/null
    then
        echo "$DC not found on your \$PATH!"
    else
        cd ..

        cat > $EXE.d <<EOF
module ${EXE};

void main() {}
EOF

        rebuild -debug=UnitTest -debug -full -clean -unittest -version=UnitTest $EXE.d tango/core/*.d tango/io/digest/*.d tango/io/model/*.d tango/io/protocol/*.d tango/io/selector/*.d tango/io/*.d tango/math/*.d tango/net/ftp/*.d tango/net/http/*.d tango/net/model/*.d tango/stdc/stringz.d tango/sys/*.d tango/text/convert/*.d tango/text/locale/Collation.d tango/text/locale/Convert.d tango/text/locale/Core.d tango/text/locale/Data.d tango/text/locale/Locale.d tango/text/locale/Parse.d tango/text/locale/Posix.d tango/text/stream/*.d tango/text/*.d tango/util/*.d tango/util/collection/model/*.d tango/util/collection/*.d tango/util/collection/iterator/*.d tango/util/collection/impl/*.d tango/util/locks/*.d tango/util/log/model/*.d tango/util/log/*.d tango/util/time/chrono/*.d tango/util/time/*.d -dc=$DC-posix-tango

        mv $EXE lib/$EXE
        cd lib/
    fi

}

compile dmd runUnitTest_dmd
compile gdc runUnitTest_gdc
