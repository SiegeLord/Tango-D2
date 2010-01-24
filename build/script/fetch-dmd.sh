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
    wget http://ftp.digitalmars.com/dmd.$VERSION.zip
fi
unzip dmd.$VERSION.zip

# copy files
cp dmd/$OS/bin/dmd ../bundle/bin/
cp dmd/$OS/bin/dumpobj ../bundle/bin/
cp dmd/$OS/bin/obj2asm ../bundle/bin/
cp dmd/$OS/bin/rdmd ../bundle/bin/
cp dmd/$OS/bin/README.TXT ../bundle/bin/

chmod +x ../bundle/bin/dmd
chmod +x ../bundle/bin/dumpobj
chmod +x ../bundle/bin/obj2asm
chmod +x ../bundle/bin/rdmd

popd
