#!/bin/bash
# destDir should become ../../common/tango/stdc/constants
destDir=../../../tango/stdc/constants/autoconf
if [[ -n ${0%/*} ]] ; then
    cd ${0%/*}
fi
cd generators
rm -rf $destDir
mkdir -p $destDir
for f in *.c ; do
    ../dpp2.sh $* "$f" > "$destDir/${f%.*}.d"
done
