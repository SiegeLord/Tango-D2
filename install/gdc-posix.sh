#!/bin/bash
die() {
    echo "$1"
    exit 1
}

if [ ! "$4" ]
then
    echo 'Use: install/gdc-posix.sh <tango version> <GCC version> <GDC version> <DSSS version>'
    exit 1
fi

TANGO_VERSION="$1"
GCC_VERSION="$2"
GDC_VERSION="$3"
DSSS_VERSION="$4"
BASEDIR="$PWD"

# Download various utilities
mkdir -p dl
cd dl || die "Failed to cd to dl."

wget -c http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-core-$GCC_VERSION.tar.bz2 ||
    die "Failed to download gcc $GCC_VERSION"

if [ "`echo $GDC_VERSION | grep '^r'`" ]
then
    svn co -$GDC_VERSION https://dgcc.svn.sourceforge.net/svnroot/dgcc/trunk/d/ d-$GDC_VERSION ||
        die "Failed to download gdc $GDC_VERSION"
else
    wget -c http://downloads.sourceforge.net/dgcc/gdc-$GDC_VERSION-src.tar.bz2 ||
        die "Failed to download gdc $GDC_VERSION"
    tar jxf gdc-$GDC_VERSION-src.tar.bz2 ||
        die "Failed to extract gdc."
    mv d d-$GDC_VERSION
fi

wget -c http://svn.dsource.org/projects/dsss/downloads/$DSSS_VERSION/dsss-$DSSS_VERSION.tar.bz2 ||
    die "Failed to download dsss $DSSS_VERSION"
cd ..

# Now build prereqs
mkdir -p build
cd build || die "Failed to cd to build"

# build gdc
rm -rf gcc-$GCC_VERSION
tar jxf ../dl/gcc-core-$GCC_VERSION.tar.bz2 ||
    die "Failed to extract gcc"
cd gcc-$GCC_VERSION/gcc ||
    die "Failed to cd into gcc"
ln -s ../../../dl/d-$GDC_VERSION d ||
    die "Failed to link gdc sources into gcc"
cd ../
./gcc/d/setup-gcc.sh || die ""
./configure --prefix="$BASEDIR/gdc" --enable-languages=c,d --enable-static --disable-shared --disable-multilib ||
    die "Failed to configure gcc"
make all ||
    die "Failed to build gcc"
make install ||
    die "Failed to install gcc"
cd ..

# build DSSS
tar jxf ../dl/dsss-$DSSS_VERSION.tar.bz2 ||
    die "Failed to extract dsss"
cd dsss-$DSSS_VERSION ||
    die "Failed to cd into dsss"
PATH="$BASEDIR/gdc/bin:$PATH" make -f Makefile.gdc.posix ||
    die "Failed to build dsss"
PATH="$BASEDIR/gdc/bin:$PATH" ./dsss install --prefix="$BASEDIR/dsss" ||
    die "Failed to install dsss"
cd ../..


# finally, build Tango and bundles
export PATH="$BASEDIR/dsss/bin:$BASEDIR/gdc/bin:$PATH"
dsss build
echo $TANGO_VERSION'-gdc'$GDC_VERSION > version.txt
./install/gdc-posix/mkinstaller.sh ||
    die "Failed to make installer"
echo $TANGO_VERSION'-gdc'$GDC_VERSION'-forDSSS' > version.txt
./install/gdc-posix-dsss/mkinstaller.sh ||
    die "Failed to make installer"
