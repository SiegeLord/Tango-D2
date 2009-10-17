#!/usr/bin/env bash
# generates the make dependencies to generate fully qualified d files out of the files
# it receives as input
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

if [ "$1" == "--help" ] ; then
    echo "usage: dep0.sh [--help] dSource1.d [dSource2.d...]"
    echo "generates the make dependencies to generate fully qualified d files out"
    echo "dSource1.d dSource2.d..."
    echo ".di files are also supported (and generate qualified .di files)"
    exit 0
fi

while [ $# -gt 0 ]
do
    sost="'s|^ *module  *\\([a-zA-Z.0-9_][a-zA-Z.0-9_]*\\) *;.*|\\1|p'"
    sedCmd="sed -n $sost $1"
    baseN=`sh -c "$sedCmd"`
    newName=
    if [ "${1: -1}" == "i" ] ; then
        newName=${baseN}.di
    else
        newName=${baseN}.d
    fi
    if [ ! "$1" -ef "$newName" ] ; then
        echo "$newName : $1"
        echo "	echo \"#line 1 \\\"\$<\\\"\" > \$@"
        echo "	cat \$< >> \$@"
        echo ".INTERMEDIATE: $newName"
        echo ".PRECIOUS: $newName"
        #echo ".SECONDARY: $newName"
    fi
    shift
done

