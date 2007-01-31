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

if [ ! -e install/gdc-posix/installer.sh ]
then
    die 1 'You must run mkinstaller.sh from the Tango base.'
fi

# 1) The core
if [ ! -e lib/libtango.a ]
then
    cd lib || die 1 "Failed to cd to lib"
    ./build-gdc.sh || die 1 "Failed to build the core"
    ./install-gdc.sh || die 1 "Failed to install the core"
    cd .. || die 1
fi

tar zcf core.tar.gz object.di lib/libgphobos.a lib/libtango.a \
    lib/install-gdc.sh || die 1 "Failed to create core.tar.gz"


# 2) The rest
if [ ! -e libSDG-tango-core.a ]
then
    dsss build || die 1 "Failed to build Tango"
fi
dsss install --prefix="`pwd`/tmp" || die 1 "Failed to install Tango"

cd tmp || die 1 "Failed to cd to temporary Tango install"
mkdir -p bin
cp ../install/gdc-posix/uninstall.sh bin/uninstall-tango-core || die 1 "Failed to install the uninstaller"
tar zcf ../tango.tar.gz * || die 1 "Failed to create tango.tar.gz"
cd .. || exit 1
rm -rf tmp || exit 1


# 3) Make the instaler proper
(
    echo -e '#!/bin/bash\nINST_GDC=0\nINST_DSSS=0' ;
    cat install/gdc-posix/installer.sh ;
    tar cf - core.tar.gz tango.tar.gz
) > tangoInstaller.sh || die 1 "Failed to create tangoInstaller.sh"
chmod 0755 tangoInstaller.sh

# 4) Clean up
rm -f core.tar.gz tango.tar.gz
