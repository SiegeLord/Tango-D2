#!/usr/bin/env bash
# excludes the given patterns
if [ "$1" == "--help" ] ; then
    echo "usage: excludeDep.sh [--help] [exclude patterns]"
    echo "combines the given patterns together and excludes them"
    exit 0
fi
combPattern=
while [ $# -gt 0 ]
do
    combPattern="${combPattern}|$1"
    shift
done
echo excluding pattern "$combPattern"
grep -v "$combPattern"
