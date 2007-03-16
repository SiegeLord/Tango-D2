#!/bin/sh
#
#
#    Copyright (c) 2006 Alexander Panek
#
# This software is provided 'as-is', without any express or implied warranty.
# In no event will the authors be held liable for any damages arising from the
# use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not claim
#    that you wrote the original software. If you use this software in a
#    product, an acknowledgment in the product documentation would be 
#    appreciated but is not required.
#
# 2. Altered source versions must be plainly marked as such, and must not
#    be misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source distribution.
#

## Variables
#
# local directories
PREFIX=/usr
#MAN_DIR=/usr/share/man/man1

# mirrors and file names
DMD_MIRROR=http://ftp.digitalmars.com
DMD_VERSION="1.009"
DMD_FILENAME=dmd.$DMD_VERSION.zip
DMD_CONF=/etc/dmd.conf
TANGO_REPOSITORY=http://svn.dsource.org/projects/tango/trunk/
TANGO_MIRROR=http://svn.dsource.org/projects/tango/downloads/
TANGO_FILENAME=tango-0.96-beta2.tar.gz
DSSS_MIRROR=http://svn.dsource.org/projects/dsss/downloads/
DSSS_FILENAME=dsss.tar.gz

# state variables
DOWNLOAD_TANGO=0
DOWNLOAD_TANGO_SVN=0
DOWNLOAD_DMD=0
DOWNLOAD_DSSS=0
INSTALL_DMD=0
INSTALL_DSSS=0

ROOT=1
CLEAN_ALL=1

## Helper functions
#
# 'exception', prints first parameter and exits script totally.
die() {
	CLEANALL=0
	RET=$1
	shift
	echo "$@"
	exit $1
}

# print usage information
usage() {
	cat <<EOF
Usage: $0 install_prefix [OPTIONS]

Options:
	--help, -h: display this text

#	--download(*): download Tango release package ($VERSION)
	--download-svn(*): check out a fresh Tango from the trunk (not recommended, 
	                   use this only if you are aware of what you are doing!)
#	--download-dmd(*): download DMD 1.0 binaries and install them
#	--download-dsss(*): download D Shared Software System binaries
#	--download-all(*): download Tango release package, DMD 1.0 and DSSS
#	--download-all-svn(*): checkout a fresh Tango from trunk, download DMD 1.0 and DSSS

#	--install-dmd: install pre-downloaded DMD package (gets automatically invoked by --download-dmd)
#	--install-dsss: install pre-downloaded DSSS package (gets automatically invoked by --download-dsss)

#	--uninstall: uninstall Tango
#	--uninstall-dmd: uninstall DMD only, leave Tango as-is
#	--uninstall-dsss: uninstall DSSS only, leave Tango and DMD as-is
#	--uninstall-all: uninstall Tango, DMD and DSSS

DMD install options:
#	--no-root: do not install a global dmd.conf (/etc/dmd.conf, by default)
#	--clean-all: remove dmd.zip after installation


	(*) these options need an active internet connections
	# these options are not implemented yet

EOF

}

# print installation summary
finished() {
	cat <<EOF


-----------------------------------------------------------------
Tango has been installed successfully.
You can find documentation at http://dsource.org/projects/tango,
or locally in $PREFIX/include/tango/doc/.

General D documentation can be found at:
  o http://digitalmars.com/d/
  o http://dsource.org/projects/tutorials/wiki
  o http://dprogramming.com/
  o http://www.prowiki.org/wiki4d/wiki.cgi?FrontPage"

Enjoy your stay in the Tango dancing club! \\\\o \\o/ o//

EOF

}

# download Tango release package
download_tango() {
	echo "Downloading Tango release package $TANGO_FILENAME from $TANGO_MIRROR"
	wget -c $TANGO_MIRROR/$TANGO_FILENAME || die 1 "Error: could not download Tango release package. Aborting."
}

download_tango_svn() {
	echo "Checking out Tango from trunk, this may take a while."

	echo "..creating temporary directory tango/..."
	mkdir -p tango/ || die 1 "Error: could not create temporary directory for checking out. Aborting."

	echo "..changing directory to tango/ ..."
	cd tango || die 1 "Error: could not change directory to tango/. Aborting."

	echo "..checking out tango/trunk (quietly)..."
	svn checkout --quiet $TANGO_REPOSITORY || die 1 "Error: could not check out	trunk. Aborting."

	echo "..changing directory to tango/trunk to continue installation..."
	cd trunk || die 1 "Error: could not change directory to tango/trunk. Aborting."

	echo "Checkout finished, continuing to build library files..."
	echo "..changing directory to tango/trunk/lib for building library files..."
	cd lib || die 1 "Error: could not change directory to tango/trunk/lib. Aborting."

	echo "..invoking build-dmd.sh to build library files, this may take a while..."
	build-dmd.sh || die 1 "Error: could not build library files. Aborting."

	echo "..moving tango/trunk/tango to tango/trunk/tango_svn..."
	mv ../tango ../tango_svn

	echo "..exporting tango/trunk/tango_svn to tango/trunk/tango (getting rid of svn files)..."
	svn export --quiet --force ../tango_svn ../tango || die 1 "Error: could not export from tango/trunk/tango_svn"

	echo "Building finished, falling back to tango/trunk/install to continue installation..."
	cd ../install || die 1 "Error: could not change directory to tango/trunk. Aborting."
}

# download DMD binary package
download_dmd() {
	echo "Downloading $DMD_FILENAME from $DMD_MIRROR..."
	wget -c $DMD_MIRROR/$DMD_FILENAME || die 1 "Error: could not download DMD. Aborting."
}

# download DSSS binary package
download_dsss() {

}

install_tango() {
	echo "Attempting to install Tango in $PREFIX..."

	mkdir -p $PREFIX/include/
	mkdir -p $PREFIX/lib/
	mkdir -p $PREFIX/doc/tango/

	cp -r ../tango/ $PREFIX/include/
	cp -r ../std/ $PREFIX/include/

	if [ -f "$PREFIX/lib/libphobos.a" ]
	then
		mv $PREFIX/lib/libphobos.a $PREFIX/lib/original_libphobos.a
	fi

	cp ../lib/libphobos.a $PREFIX/lib/

	if [ $DOWNLOAD_TANGO_SVN = 0 ]
	then
		# we *should* have a libtango.a there, too in this case
		cp ../lib/libtango.a $PREFIX/lib/
	fi

	cp -r examples/ $PREFIX/doc/tango/
}

dmd_conf_install() {
	if [ `whereis dmd | tr ' ' '\n' | grep dmd.conf -c` -lt 1 ]
	then
		# no dmd.conf found
		cat > /etc/dmd.conf <<EOF
[Environment]
DFLAGS=-I$PREFIX/include/ -version=Posix -version=Tango

EOF
	else
		mv `whereis dmd | tr ' ' '\n' | grep -v X | grep -m 1 dmd.conf`	old_dmd.conf

		cat > /etc/dmd.conf <<EOF
[Environment]
DFLAGS=-I$PREFIX/include/ -version=Posix -version=Tango

EOF
	fi		
}


if [ -n "$1" ]
then
	PREFIX="$1"
else
	usage
	die 1
fi

if [ -z `"echo ${PREFIX} | grep '^/'"` ]
then
	PREFIX="`pwd`${PREFIX}"
fi

for i in $*;
do
	case "$i" in
		-h)
			usage
			die 1
		;;

		--help)
			usage
			die 1
		;;

		--download)
			DOWNLOAD=1
		;;

		--download-svn)
			DOWNLOAD_SVN=1
		;;
	esac
done

if [ $DOWNLOAD_TANGO = 1 ]
then
	download_tango
fi

if [ $DOWNLOAD_TANGO_SVN = 1 ]
then
	download_tango_svn
fi

install_tango

finished
