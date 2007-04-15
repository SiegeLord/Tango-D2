#!/bin/bash -x 
# Copyright (C) 2007  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.

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
if [ -e .svn ]
then
    TANGO_VERSION="r`svn info | grep '^Revision: ' | sed 's/Revision: //'`"
elif [ -e version.txt ]
then
	TANGO_VERSION="`cat version.txt`"
fi




# 1) The core
if [ ! -e lib/libphobos.a ]
then
    cd lib || die 1 "Failed to cd to lib"
    ./build-dmd.sh || die 1 "Failed to build the core"
    ./install-dmd.sh || die 1 "Failed to install the core"
    cd .. || die 1
fi

tar zcf core.tar.gz object.di lib/libphobos.a \
    lib/install-dmd.sh || die 1 "Failed to create core.tar.gz"


# 2) The rest
if [ ! -e libgtango.a ]
then
    dsss build || die 1 "Failed to build Tango"
    rm -rf libtango_objs
    mkdir -p libtango_objs
    cd libtango_objs || die 1 "Failed to cd to libtango_objs"
    for i in ../libSDD-*.a
    do
        ar x $i
    done
    ar rc ../libtango.a *.o || die 1 "Failed to create libtango.a"
    ranlib ../libtango.a || die 1 "Failed to ranlib libtango.a"
    cd .. || die 1 "Failed to cd out of libtango_objs"
fi
mkdir -p tmp
cd tmp || die 1 "Failed to cd to temporary Tango install"

mkdir -p bin
cp ../install/dmd-posix/uninstall.sh bin/uninstall-tango-core || die 1 "Failed to install the uninstaller"

mkdir -p import
cp -pR ../tango import || die 1 "Failed to copy in the tango .d files"

mkdir -p lib
cp ../libtango.a lib || die 1 "Failed to copy in the tango .a file"

find import/tango -name .svn | xargs rm -rf
tar zcf ../tango.tar.gz * || die 1 "Failed to create tango.tar.gz"
cd .. || exit 1
rm -rf tmp || exit 1


# 3) Make the installer proper
(
    echo -e '#!/bin/bash -x\nINST_DMD=0' ;
    cat install/dmd-posix/installer.sh ;
    tar cf - core.tar.gz tango.tar.gz
) > tango-$TANGO_VERSION-dmd-posix.sh || die 1 "Failed to create the installer"
chmod 0755 tango-$TANGO_VERSION-dmd-posix.sh

# 4) DMD 
if [ -e dmd ]
then
	cd dmd || die 1 "Failed to cd to dmd"

	# No cleaning up needed here, arr.

    tar zcf ../dmd.tar.gz * || die 1 "Failed to create dmd.tar.gz"

	cd .. || exit 1

    (
        echo -e '#!/bin/bash -x\nINST_DMD=1' ;
        cat install/dmd-posix/installer.sh ;
        tar cf - core.tar.gz tango.tar.gz dmd.tar.gz
    ) > tango-$TANGO_VERSION-dmd-posix-withDMD.sh || die 1 "Failed to create the installer with DMD"
    chmod 0755 tango-$TANGO_VERSION-dmd-posix-withDMD.sh
fi

# 5) Clean up
rm -f core.tar.gz tango.tar.gz dmd.tar.gz
