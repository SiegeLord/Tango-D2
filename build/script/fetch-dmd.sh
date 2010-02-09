#!/usr/bin/env bash

# read config info
VERSION=`cat dmd.version.txt`
OS=`cat dmd.osname.txt`

# enter downloads folder
if [ ! -e downloads ]
then
    mkdir downloads
fi

pushd downloads

# clear and download DMD
rm -rf dmd
if [ ! -e dmd.$VERSION.zip ]
then
    curl http://ftp.digitalmars.com/dmd.$VERSION.zip -o dmd.$VERSION.zip
fi
unzip dmd.$VERSION.zip

# copy files
cp dmd/$OS/bin/dmd ../tango-bundle/bin/
cp dmd/$OS/bin/dumpobj ../tango-bundle/bin/
cp dmd/$OS/bin/obj2asm ../tango-bundle/bin/
cp dmd/$OS/bin/rdmd ../tango-bundle/bin/
cp dmd/$OS/bin/README.TXT ../tango-bundle/bin/

chmod +x ../tango-bundle/bin/dmd
chmod +x ../tango-bundle/bin/dumpobj
chmod +x ../tango-bundle/bin/obj2asm
chmod +x ../tango-bundle/bin/rdmd

popd
