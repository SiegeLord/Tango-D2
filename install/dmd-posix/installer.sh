#!/bin/bash
# Copyright (C) 2007  Gregor Richards
# Permission is granted to do anything you please with this software.
# This software is provided with no warranty, express or implied, within the
# bounds of applicable law.
#
# Modifications by Alexander Panek, Lars Ivar Igesund

die() {
    rm -rf /tmp/tango.installer.$$
    ERROR="$1"
    shift
    echo "$@"
    exit $ERROR
}

usage() {
    echo 'Usage: <installer-name>.sh [--prefix <install prefix>]
Options:
  --prefix:  Install prefix is optional on the command line, if not set it
             will be requested during install. The set prefix needs to be
             an absolute path.'
    exit 0
}


# Figure out our complete name
ORIGDIR=`pwd`
cd `dirname $0`
FULLNAME="`pwd`/`basename $0`"
cd $ORIGDIR

# parse arguments
while [ "$#" != "0" ]
do
    if [ "$1" = "--prefix" ]
    then
        shift

        PREFIX="$1"
    else
        usage
    fi
    shift
done

# Create our temporary directory
TTMP=/tmp/tango.installer.$$
mkdir -p $TTMP || die 1 "Failed to create temporary directory"

# This installer works by black magic: The following number must be the exact
# number of lines in this file+3:
LINES=150

# Install DMD if necessary
DMDDIR=
if [ "$INST_DMD" = "1" ]
then
	if [ ! "$PREFIX" ]
	then
		echo -n "What prefix do you want to install DMD to (absolute path)? "
		read DMDDIR
	else
		DMDDIR="$PREFIX"
	fi

    if [ "${DMDDIR:0:1}" != "/" ]
    then
        die 1 "The PREFIX needs to be an absolute path"
    fi

	export PATH="$DMDDIR/bin:$PATH"
	mkdir -p $DMDDIR/bin || die 1 "Failed to create the DMD install directory"
	cd $DMDDIR/bin || die 1 "Failed to cd to the DMD install directory"
    tail -n+$LINES $FULLNAME | tar Oxf - dmd.tar.gz | gunzip -c | tar xf - || die 1 "Failed to extract DMD"
else
    DMDDIR="$PREFIX"
fi

# Make sure DMD is installed
if [ ! "$DMDDIR" ]
then
	dmd --help > /dev/null 2> /dev/null
	if [ "$?" = "127" ]
	then
		echo -n "What path is DMD installed to?"
		read DMDDIR
		export PATH="$DMDDIR/bin:$PATH"
		if [ ! -e $DMDDIR/bin/dmd ]
		then
			die 1 "DMD is not installed to that path!"
		fi
	else
		# Get our proper DMD prefix
		OLDIPS="$IPS"
		IPS=:
		for i in `echo $PATH | sed 's/:/ /g'`
		do
			if [ -e "$i/bin/dmd" ]
			then
				DMDDIR="$i"
				break
			fi
		done
		IPS="$OLDIPS"
	fi
fi

if [ "${DMDDIR:0:1}" != "/" ]
then
    die 1 "The PREFIX needs to be an absolute path"
fi


# Then, cd to our tmpdir and extract core.tar.gz
cd $TTMP || die 1 "Failed to cd to temporary directory"

tail -n+$LINES $FULLNAME | tar Oxf - core.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract the Tango core"

# And install it
cd lib || die 1 "Tango core improperly archived"
# Just in case it's already installed, uninstall it
./install-dmd.sh --uninstall > /dev/null 2> /dev/null
./install-dmd.sh --prefix $DMDDIR --verify > /dev/null 2> /dev/null || die 1 "Failed to install Tango core"

if [ ! -e "$DMDDIR/bin/dmd.conf" ]
then
    die 1 "Error in install, no dmd.conf found"
else
    if [ ! "`grep '\-L\-ltango' $DMDDIR/bin/dmd.conf`" ]
    then
        sed -i.bak -e 's/^DFLAGS=.*$/& -L-ltango-user-dmd/' $DMDDIR/bin/dmd.conf
    fi
fi


# Then install the rest of Tango
cd $DMDDIR || die 1 "Failed to cd to DMD's installed prefix"
tail -n+$LINES $FULLNAME | tar Oxf - tango.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract Tango"

echo 'Done!'
echo "Remember to update your PATH as necessary. You installed to the prefix $DMDDIR"
echo "Run 'tango-dmd-tool --uninstall $DMDDIR' to uninstall Tango"

exit 0
