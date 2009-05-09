#!/bin/sh
#preprocess DD files
CPP=`which gcc`
if [ -e $CPP ]
    then CPP="gcc -E -dD -P -C "
else
    CPP=`which cpp`
fi

$CPP $* | sed -e '/^# [0-9]{1,} / d' -e 's/__XYX__//g'
