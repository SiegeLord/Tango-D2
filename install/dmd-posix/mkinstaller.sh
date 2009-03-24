#!/bin/bash
# Copyright (C) 2007  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.
#
# Modifications by Alexander Panek, Lars Ivar Igesund

die() {
    ERROR="$1"
    shift
    echo "$@"
    exit $ERROR
}

if [ ! -e install/dmd-posix/installer.sh ]
then
	die 1 'You must run mkinstaller.sh from the Tango base.'
fi

# Figure out the version of Tango
TANGO_VERSION=0.0
if [ -e version.txt ]
then
    TANGO_VERSION="`cat version.txt`"
    DMD_VERSION="`cat dmdversion.txt`"
elif [ -e .svn ]
then
    TANGO_VERSION="r`svn info | grep '^Revision: ' | sed 's/Revision: //'`"
fi

# 1) The core
if [ ! -e lib/libtango-base-dmd.a ]
then
    cd lib || die 1 "Failed to cd to lib"
    ./build-dmd.sh || die 1 "Failed to build the core"
    cd .. || die 1
fi

tar zcf core.tar.gz object.di lib/libtango-base-dmd.a \
    lib/install-dmd.sh || die 1 "Failed to create core.tar.gz"


# 2) The rest
if [ ! -e libtango-user-dmd.a ]
then
    cd lib || die 1 "Failed to cd to lib"
    ./build-tango.sh dmd || die 1 "Failed to build Tango"
    cd .. || die 1 "Failed to cd out of lib"
    chmod 644 tango/core/*.di
fi
mkdir -p tmp
cd tmp || die 1 "Failed to cd to temporary Tango install"

mkdir -p bin
cp ../install/dmd-posix/tango-dmd-tool bin/tango-dmd-tool || die 1 "Failed to install the uninstaller"

# Clear old include/d files
rm -rf include/d/tango/tango include/d/tango/std include/d/tango include/d/std

mkdir -p include/d
cp -pR ../tango include/d || die 1 "Failed to copy in the tango .d files"
cp -pR ../std include/d || die 1 "Failed to copy in the std .d files"

mkdir -p lib
cp ../lib/libtango-user-dmd.a lib || die 1 "Failed to copy in the tango .a file"
cp ../lib/dmdinclude lib || die 1 "Failed to copy in the dmdinclude file"

find include/d -name .svn | xargs rm -rf
tar zcf ../tango.tar.gz include lib bin || die 1 "Failed to create tango.tar.gz"
cd .. || exit 1
rm -rf tmp || exit 1

# 3) Make the installer proper
(
    echo -e '#!/bin/bash -x\nINST_DMD=0' ;
    cat install/dmd-posix/installer.sh ;
    tar cf - core.tar.gz tango.tar.gz
) > tango-$TANGO_VERSION-dmd.$DMD_VERSION-posix.sh || die 1 "Failed to create the installer"
chmod 0755 tango-$TANGO_VERSION-dmd.$DMD_VERSION-posix.sh

# 4) DMD
if [ -e dmd ]
then
	cd dmd || die 1 "Failed to cd to dmd"

    # Make sure all binaries are executable
    chmod a+x bin/dmd
    chmod a+x bin/dumpobj
    chmod a+x bin/obj2asm
    chmod a+x bin/rdmd

	# No cleaning up needed here, arr.
    tar zcf ../dmd.tar.gz * || die 1 "Failed to create dmd.tar.gz"

	cd .. || exit 1

    (
        echo -e '#!/bin/bash\nINST_DMD=1' ;
        cat install/dmd-posix/installer.sh ;
        tar cf - core.tar.gz tango.tar.gz dmd.tar.gz
    ) > tango-$TANGO_VERSION-dmd.$DMD_VERSION-posix-withDMD.sh || die 1 "Failed to create the installer with DMD"
    chmod 0755 tango-$TANGO_VERSION-dmd.$DMD_VERSION-posix-withDMD.sh
fi

# 5) Clean up
rm -f core.tar.gz tango.tar.gz dmd.tar.gz
