#!/bin/sh
#preprocess DD files
CPP=`which cpp`
if [[ -z $CPP ]]
    then CPP="gcc -E"
fi
$CPP -P -C $1 | sed -E -e '1,/xx*  *start  *xx*/ d' -e '/^# [0-9]{1,} / d' -e 's/__XYX__//g'
