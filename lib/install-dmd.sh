#!/bin/bash

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

# local directories
PREFIX=/usr/local
MAN_DIR=/usr/share/man/man1
# mirrors & filename
DMD_MIRROR=http://ftp.digitalmars.com
DMD_FILENAME=dmd.zip
TANGO_REPOSITORY=http://svn.dsource.org/projects/tango/trunk/
# state variables (changable through --flags)
NOROOT=0
DMD_DOWNLOAD=0
TANGO_DOWNLOAD=0
DMD_INSTALL=0
#

## HELPER FUNCTIONS

# 'exception', prints first parameter and exits script totally.
die() {
	echo "$1"
	exit 0
}

# prints usage
usage() {
	echo 'Usage: install-dmd.sh <install prefix> [OPTIONS]'
	echo ''
	echo 'Options:'
	echo '  --dmd: install DMD too (requires a dmd.zip in the current directory; use --download to get a fresh copy)'
	echo '         If you want to download DMD yourself, please go to http://digitalmars.com/d/ .'
	echo '  --download: checkout a fresh copy of Tango (subversion required)'
	echo '  --download-dmd: Download a fresh copy of DMD (implies --dmd)'
	echo '  --version=[x[.]]xxx : Download a specific version of DMD (for example 0.176 will download dmd.176.zip)'
	echo '  --download-all: Download DMD and checkout a fresh copy of Tango
	(implies --dmd, too)'
	echo '  --no-root: Do not install /etc/dmd.conf'
	echo '  --uninstall: Uninstall Tango'
	echo '  --uninstall-all: Uninstall Tango and DMD'
	echo '  --help: Display this text'
	echo ' '
}

download_dmd() {
	echo "Downloading dmd.zip from ${DMD_MIRROR}..."
	wget ${DMD_MIRROR}/${DMD_FILENAME} || die "Error downloading DMD. Aborting."
}

download_tango() {
	echo "Downloading Tango from ${TANGO_MIRROR} (subversion required)..."


	echo "..creating temporary directory tango/..."
	mkdir -p tango || die "Error while creating temporary directory."

	echo "..changing directory to tango/..."
	cd tango || die "Error while changing directory (tango/)."

	echo "..checking out tango/trunk quietly .. this may take some time..."
	svn checkout ${TANGO_REPOSITORY} || die "Error while checking out."

	echo "..changing directory to tango/trunk/..."
	cd trunk || die "Error while changing directory (tango/trunk/)."
}

install_dmd() {
	unzip_dmd
	copy_dmd
	copy_dmd_include
	copy_dmd_lib
	copy_dmd_doc
	dmd_conf_install
	cleanup_dmd
}

unzip_dmd() {
	if [ ! -f ${DMD_FILENAME} ]
	then
		die "Could not find dmd.zip. Please use --download-dmd or manually download the file from ${DMD_MIRROR}. Aborting."
	fi

	echo "Extracting dmd.zip..."
	unzip -q -d . ${DMD_FILENAME} || die 'Could not unzip dmd.zip. Aborting.'
}

copy_dmd() {
	echo "Copying compiler binaries..."

	echo "..creating ${PREFIX}/bin"
	mkdir -p ${PREFIX}/bin || die "Error creating directory (${PREFIX}/bin)."

	echo "..settin executable flag for dmd, objasm, dumpobj and rdmd..."
	chmod +x dmd/bin/{dmd,objasm,dumpobj,rdmd} || die "Error chmod-ing (dmd, objasm, dumpobj, rdmd)."

	echo "..copying executable files to ${PREFIX}/bin..."
	cp dmd/bin/dmd ${PREFIX}/bin || die "Error copying dmd/bin/dmd."
	cp dmd/bin/obj2asm ${PREFIX}/bin || die "Error copying dmd/bin/objasm."
	cp dmd/bin/dumpobj ${PREFIX}/bin || die "Error copying dmd/bin/dumpobj."
	cp dmd/bin/rdmd ${PREFIX}/bin || die "Error copying dmd/bin/rdmd."
}

copy_dmd_include() {
	echo "Copying runtime library sources..."

	echo "..creating ${PREFIX}/include"
	mkdir -p ${PREFIX}/include || die "Error creating ${PREFIX}/include."

	echo "..copying files"
	cp dmd/src/phobos ${PREFIX}/include || die "Error copying library sources to ${PREFIX}/include."
}

copy_dmd_doc() {
	echo "Copying documentation and samples..."

	echo "..creating directories ${PREFIX}/doc/dmd/{src,samples}..."
	mkdir -p {${PREFIX}/doc/dmd/samples, ${PREFIX}/doc/dmd/src} || die "Error creating documentation directories."

	cp dmd/html/d/* ${PREFIX}/doc/dmd/ || die "Error copying documentation."
	cp dmd/samples/d/* ${PREFIX}/doc/dmd/samples/ || die "Error copying samples."
	cp dmd/src/dmd/* ${PREFIX}/dmd/src/ || die "Error copying source."
}

copy_dmd_lib() {
	echo "Copying runtime library..."

	echo "..creating ${PREFIX}/lib..."
	mkdir -p ${PREFIX}/lib || die "Error creating directory for runtime library (${PREFIX}/lib)."

	echo "..copying libphobos.a and phobos.lib"
	cp dmd/lib/libphobos.a ${PREFIX}/lib/ || die "Error copying libphobos.a."
	cp dmd/lib/phobos.lib ${PREFIX}/lib/ || die "Error copying phobos.lib."
}

copy_dmd_man() {
	echo "Copying manpages to ${MAN_DIR}"
	cp dmd/man/man1/* ${MAN_DIR} || die "Error copying manpages."
}

install_tango() {
	echo "Installing Tango..."

	echo "..checking if we have a local copy of the repository or an extracted package..."
	if [ `find . -name .svn | grep '' -c` -gt 0 ]
	then
		echo "...svn files found, using svn export to copy (avoiding recreation of .svn* files)..."

		echo "...checking if directory already exists (svn export will fail, if so)..."
		if [ -f ${PREFIX}/include/tango ]
		then
			die "Error, destination does already exist; please delete it or change prefix."
		else
			echo "....everything fine; doing svn export..."
			mkdir -p ${PREFIX}/include
			svn export . ${PREFIX}/include/tango || die "Error exporting Tango via svn export."
		fi
	else
		"...no subversion files found, using normal copy method..."
		echo "...creating directory ${PREFIX}/include..."
		mkdir -p ${PREFIX}/include/tango || die "Error creating Tango directory."
		cp -r ./* ${PREFIX}/include/tango || die "Error copying Tango to new directory."
	fi
}

dmd_conf_install() {
	echo "Modifying or creating dmd.conf file (first found by whereis command)..."

	echo "..trying to find dmd.conf..."
	if [ `whereis dmd | tr ' ' '\n' | grep dmd.conf -c` -lt 1 ]
	then
		echo "..no dmd.conf found, installing default one to /etc/dmd.conf..."

		# no dmd.conf installed yet, install a fresh one!
		echo -n "[Environment]" > /etc/dmd.conf || die "Error writing to /etc/dmd.conf."
		echo -n ";DFLAGS=-I\"${PREFIX}/include/phobos -L-L${PREFIX}/lib\"" >> /etc/dmd.conf || die "Error writing to /etc/dmd.conf."
		echo -n "DFLAGS=-I\"${PREFIX}/include/tango -L-L${PREFIX}/lib/\"" >> /etc/dmd.conf || die "Error writing to /etc/dmd.conf."
	else
		echo -n "..dmd.conf found: `whereis dmd | tr ' ' '\n' | grep dmd.conf -m 1` -- doing sed magic."

		sed -e 's/DFLAGS=-I.*phobos.*/;&\nDFLAGS=-I"\${PREFIX}\/include\/tango\/ -L-L\${PREFIX}\/lib\/"/g' `whereis dmd | tr ' ' '\n' | grep -v X | grep -m 1 dmd.conf` > _dmd.conf || die
		mv _dmd.conf `whereis dmd | tr ' ' '\n' | grep -v X | grep -m 1 dmd.conf` || die # replace old dmd.conf with changed dmd.conf
	fi
}

cleanup_tango() {
	echo "Cleaning up (removing) tango/trunk/..."

	cd ../../ || die "Error while cleaning up."
	rm -rf tango || die "Error while cleaning up."
}
	
cleanup_dmd() {
	echo "Cleaning up tango/trunk/dmd/..."

	rm -rf dmd/ || die "Error while cleaning up."

	if [ ${CLEANALL} = 1 ]
	then
		echo "Removing dmd.zip too..."
		rm -r dmd.zip || die "Error while removing dmd.zip."
	fi
}

finished() {
	echo ""
	echo "-----------------------------------------------------------------"
	echo "Tango has been installed successfully."
	echo "You can find documentation at http://dsource.org/projects/tango,"
	echo "or locally in ${PREFIX}/include/tango/doc/."
	echo ""
	echo "General D documentation is found at:"
	echo "  o http://digitalmars.com/d/"
	echo "  o http://dsource.org/projects/tutorials/wiki"
	echo "  o http://dprogramming.com/"
	echo "  o http://www.prowiki.org/wiki4d/wiki.cgi?FrontPage"
	echo ""
	echo "Enjoy your stay in the Tango dancing club! \\\\o \\o/ o//"
}

############################################################################################
############################################################################################
# ACTUAL START OF THE SCRIPT (or end of functions, depends on your pessimism/optimism ;) )
############################################################################################
############################################################################################

if [ -n "$1" ]
then
	PREFIX=$1
else
	usage
	die
fi

# Check for flags
for i in $*; 
do
	case "$i" in
		--dmd)
			DMD_INSTALL=1
		;;
		--download)
			TANGO_DOWNLOAD=1
		;;
		--download-dmd)
			DMD_DOWNLOAD=1
			DMD_INSTALL=1
		;;
		--download-all)
			DMD_DOWNLOAD=1
			DMD_INSTALL=1
			TANGO_DOWNLOAD=1
		;;
		--no-root)
			NOROOT=1
		;;
		--version=*)
			VERSION=`echo -n "${i}" | sed -n 's/^--version=[0-9]\?\.\?\([0-9]\{3\}\)/\1/p'` 
			
			if [  -n "${VERSION}" ]
			then
				DMD_FILENAME="dmd.${VERSION}.zip"
			else
				DMD_FILENAME="dmd.zip"
			fi
		;;
		--help)
			usage
			die
		;;
	esac
done

if [ ${DMD_DOWNLOAD} = 1 ]
then
	download_dmd
fi

if [ ${TANGO_DOWNLOAD} = 1 ]
then
	download_tango
fi

if [ ${DMD_INSTALL} = 1 ]
then
	install_dmd
fi

install_tango

if [ ${NOROOT} = 0 ]
then
	dmd_conf_install
fi

if [ ${TANGO_DOWNLOAD} = 1 ]
then
	cleanup_tango
fi

finished
