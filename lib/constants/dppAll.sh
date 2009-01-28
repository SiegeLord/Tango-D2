#!/bin/bash
# destDir should become ../../common/tango/stdc/constants
destDir=../current
if [[ -n ${0%/*} ]] ; then
    cd ${0%/*}
fi
cd generators
rm -rf $destDir
mkdir -p $destDir
for f in *.dpp ; do
    ../dpp.sh "$f" > "$destDir/${f%.dpp}.d"
done
