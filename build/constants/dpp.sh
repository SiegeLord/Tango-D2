#!/bin/sh
#preprocess DD files
CPP=`which gcc`
if [ -e $CPP ]
    then CPP="gcc -E"
else
    CPP=`which cpp`
fi
$CPP -P -C $* | sed -e '1,/xx*  *start  *xx*/ d' -e '/^# [0-9]{1,} / d' -e 's/__XYX__//g'
