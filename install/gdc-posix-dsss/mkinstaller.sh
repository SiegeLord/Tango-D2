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

if [ ! -e install/gdc-posix-dsss/installer.sh ]
then
    die 1 'You must run mkinstaller.sh from the Tango base.'
fi

# Figure out the version of Tango
TANGO_VERSION=0.0
if [ -e version.txt ]
then
    TANGO_VERSION="`cat version.txt`"
elif [ -e .svn ]
then
    TANGO_VERSION="r`svn info | grep '^Revision: ' | sed 's/Revision: //'`"
fi

# Figure out our platform
PLATFORM="`gdc -dumpmachine`"

# 1) The core
if [ ! -e lib/libgphobos.a ]
then
    cd lib || die 1 "Failed to cd to lib"
    ./build-gdc.sh || die 1 "Failed to build the core"
    ./install-gdc.sh || die 1 "Failed to install the core"
    cd .. || die 1
fi

tar zcf core.tar.gz object.di lib/libgphobos.a \
    lib/install-gdc.sh || die 1 "Failed to create core.tar.gz"


# 2) The rest
if [ ! -e libDG-tango-core.a ]
then
    dsss build || die 1 "Failed to build Tango"
fi
dsss install --prefix="`pwd`/tmp" || die 1 "Failed to install Tango"

cd tmp || die 1 "Failed to cd to temporary Tango install"
mkdir -p bin
cp ../install/gdc-posix-dsss/uninstall.sh bin/uninstall-tango-core || die 1 "Failed to install the uninstaller"
tar zcf ../tango.tar.gz * || die 1 "Failed to create tango.tar.gz"
cd .. || exit 1
rm -rf tmp || exit 1


# 3) Make the installer proper
(
    echo -e '#!/bin/bash\nINST_GDC=0\nINST_DSSS=0' ;
    cat install/gdc-posix-dsss/installer.sh ;
    tar cf - core.tar.gz tango.tar.gz
) > tango-$TANGO_VERSION-gdc-$PLATFORM.sh || die 1 "Failed to create the installer"
chmod 0755 tango-$TANGO_VERSION-gdc-$PLATFORM.sh

# Plus a tarball
mkdir tango-$TANGO_VERSION-gdc-$PLATFORM || die 1 "Failed to mkdir tango-$TANGO_VERSION-gdc-$PLATFORM"
cd tango-$TANGO_VERSION-gdc-$PLATFORM || die 1 "Failed to cd into tango-$TANGO_VERSION-gdc-$PLATFORM"
tar zxf ../core.tar.gz || die 1 "Failed to extract core.tar.gz"
tar zxf ../tango.tar.gz || die 1 "Failed to extract tango.tar.gz"
mv object.di include
rm -f lib/install-gdc.sh
cd .. || die 1 "Failed to cd out of tango-$TANGO_VERSION-gdc-$PLATFORM"
tar zcf tango-$TANGO_VERSION-gdc-$PLATFORM.tar.gz tango-$TANGO_VERSION-gdc-$PLATFORM/

# 4) DSSS
if [ -e dsss ]
then
    cd dsss || die 1 "Failed to cd to dsss"
    find . -type f | xargs strip --strip-unneeded
    echo 'profile=gdc-posix-tango' > etc/rebuild/default
    tar zcf ../dsss.tar.gz * || die 1 "Failed to create dsss.tar.gz"
    cd .. || exit 1

    (
        echo -e '#!/bin/bash\nINST_GDC=0\nINST_DSSS=1' ;
        cat install/gdc-posix-dsss/installer.sh ;
        tar cf - core.tar.gz tango.tar.gz dsss.tar.gz
    ) > tango-$TANGO_VERSION-gdc-$PLATFORM-withDSSS.sh || die 1 "Failed to create the installer with DSSS"
    chmod 0755 tango-$TANGO_VERSION-gdc-$PLATFORM-withDSSS.sh

    # 5) GDC
    if [ -e gdc ]
    then
        cd gdc || die 1 "Failed to cd to gdc"

        # Clean it up
        rm -rf \
          bin/*++* \
          bin/cpp* \
          bin/gcc* \
          bin/gcov* \
          bin/*-linux-gnu-* \
          bin/*-mingw32-* \
          include/c++ \
          info \
          lib/libiberty* \
          lib/libmudflap* \
          lib/libstdc++* \
          lib/libsupc++* \
          lib/gcc/*/*/include \
          libexec/gcc/*/*/cc1 \
          libexec/gcc/*/*/cc1.* \
          libexec/gcc/*/*/cc1plus* \
          man/man1/cpp* \
          man/man1/g++* \
          man/man1/gcc* \
          man/man1/gcov* \
          man/man7 \
          share
        find . -type f | xargs strip --strip-unneeded
        
        tar zcf ../gdc.tar.gz * || die 1 "Failed to create gdc.tar.gz"
        cd .. || exit 1

        (
            echo -e '#!/bin/bash\nINST_GDC=1\nINST_DSSS=1' ;
            cat install/gdc-posix-dsss/installer.sh ;
            tar cf - core.tar.gz tango.tar.gz dsss.tar.gz gdc.tar.gz
        ) > tango-$TANGO_VERSION-gdc-$PLATFORM-withDSSS-withGDC.sh || die 1 "Failed to create the installer with DSSS and GDC"
        chmod 0755 tango-$TANGO_VERSION-gdc-$PLATFORM-withDSSS-withGDC.sh
    fi
fi

# 6) Clean up
rm -f core.tar.gz tango.tar.gz dsss.tar.gz gdc.tar.gz
