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

pushd bundle
BUNDLE=
# deal with compiler
if [ $DMD == 1 ]
then
    ../export/build/script/fetch-dmd.sh
    # create tar.gz
    BUNDLE=tango-bin-$PLATFORM$BITS-$DC-with-compiler.tar.gz
    tar -czf $BUNDLE *
else
    # create tar.gz
    BUNDLE=tango-bin-$PLATFORM$BITS-$DC.tar.gz
    tar -czf $BUNDLE * 
fi

# upload
curl --transfer-file $BUNDLE --user `cat $TANGOUPLOADPW` http://downloads.dsource.org/projects/tango/snapshot

popd

