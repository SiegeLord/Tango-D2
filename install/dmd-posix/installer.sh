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

# Figure out our complete name
ORIGDIR=`pwd`
cd `dirname $0`
FULLNAME="`pwd`/`basename $0`"
cd $ORIGDIR

# Create our temporary directory
TTMP=/tmp/tango.installer.$$
mkdir -p $TTMP || die 1 "Failed to create temporary directory"

# This installer works by black magic: The following number must be the exact
# number of lines in this file+3:
LINES=93

# Install DMD if necessary
DMDDIR=
if [ "$INST_DMD" = "1" ]
then
	if [ ! "$1" ]
	then
		echo -n "What prefix do you want to install DMD to?"
		read DMDDIR
	else
		DMDDIR="$1"
	fi

	export PATH="$DMDDIR/bin:$PATH"
	mkdir -p $DMDDIR/bin || die 1 "Failed to create the DMD install directory"
	cd $DMDDIR || die 1 "Failed to cd to the DMD install directory"
    tail -n+$LINES $FULLNAME | tar Oxf - dmd.tar.gz | gunzip -c | tar xf - || die 1 "Failed to extract DMD"

    if [ ! -e "bin/dmd.conf" ]
    then
        die 1 "Error in install, no dmd.conf found"
    else
        if [ ! "`grep -L-ltango bin/dmd.conf`" ]
        then
            sed -i.bak -e 's/^DFLAGS=.*$/& -L-ltango/' bin/dmd.conf
        fi
    fi

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

# Then, cd to our tmpdir and extract core.tar.gz
cd $TTMP || die 1 "Failed to cd to temporary directory"

tail -n+$LINES $FULLNAME | tar Oxf - core.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract the Tango core"

# And install it
cd lib || die 1 "Tango core improperly archived"
# Just in case it's already installed, uninstall it
./install-dmd.sh --uninstall > /dev/null 2> /dev/null
./install-dmd.sh > /dev/null 2> /dev/null || die 1 "Failed to install Tango core"

# Then install the rest of Tango
cd $DMDDIR/bin || die 1 "Failed to cd to DMD's installed prefix"
tail -n+$LINES $FULLNAME | tar Oxf - tango.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract Tango"

echo 'Done!'
exit 0
