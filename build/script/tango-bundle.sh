#!/usr/bin/env bash

# Env variables PLATFORM and DC must be set before running this script
# Env variable BITS should be set to 64 on 64 bit platforms, otherwise nothing
# Env variable TANGOUPLOADPW must be set to a file holding "user:pass"
# The compiler used must be on the path

# For a bundle with the compiler in it, use --dmd (only compiler supported sofar)

while [ "$#" != "0" ]
do
    case "$1" in
        --dmd)
            DMD=1
            ;;
    esac
    shift
done
 
# clean old
rm -rf tango-bundle export trunk 

# check out
svn co http://svn.dsource.org/projects/tango/trunk

# export
svn export --force trunk export

# create tango-bundle dirs
mkdir -p tango-bundle/bin
mkdir -p tango-bundle/lib
mkdir -p tango-bundle/import

# copy binaries and config
cp export/build/bin/linux$BITS/* tango-bundle/bin
cp dmd.conf tango-bundle/bin/

# copy imports and .txt
cp -r export/tango tango-bundle/import
cp export/object.di tango-bundle/import
cp export/*.txt tango-bundle
rm -rf tango-bundle/import/tango/core/rt

# create library
pushd export
build/bin/$PLATFORM$BITS/bob -v -u -r=$DC -c=$DC -p=$PLATFORM -l=libtango-$DC . 
cp libtango-$DC.a ../tango-bundle/lib
popd

BUNDLE=
# deal with compiler
if [ $DMD = 1 ]
then
    export/build/script/fetch-dmd.sh
    # name bundle file
    DMDVER=`cat dmd.version.txt`
    BUNDLE=tango-bin-$PLATFORM$BITS-with-$DC.$DMDVER.tar.gz
else
    # name bundle file
    BUNDLE=tango-bin-$PLATFORM$BITS-$DC.tar.gz
fi

#package
tar -czf $BUNDLE tango-bundle 

# upload
curl --upload-file $BUNDLE --user `cat $TANGOUPLOADPW` http://downloads.dsource.org/projects/tango/snapshot/

