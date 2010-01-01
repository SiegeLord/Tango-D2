#!/bin/bash

# clean old
rm -rf bundle export trunk *.o *.a

# check out
svn co http://svn.dsource.org/projects/tango/trunk

# export
svn export --force trunk export

# create bundle dirs
mkdir -p bundle/bin
mkdir -p bundle/lib
mkdir -p bundle/import

# copy binaries
cp export/build/bin/linux$BITS/* bundle/bin

# copy imports and .txt
cp -r export/tango bundle/import
cp export/object.di bundle/import
cp export/*.txt bundle
rm -rf bundle/import/tango/core/rt

# create library
export/build/bin/$PLATFORM$BITS/bob -u -r$DC -c$DC -p$PLATFORM export -llibtango-$DC
cp libtango-$DC.a bundle/lib

# create tar.gz
pushd bundle
tar -czf tango-bin-$PLATFORM$BITS-$DC.tar.gz * 
popd
