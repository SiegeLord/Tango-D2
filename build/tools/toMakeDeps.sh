#!/usr/bin/env bash
# extracts the dependencies from the compiler -v log and formats them 
# in a make friendly way. The target of the dependency is the first argument if given
# dependencies on .di files are ignored (change???)
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

target=
while [ $# -gt 0 ]
do
    case $1 in
    --help)
        echo "usage: toMakeDeps.sh [--help] [target [exclude patterns]]"
        echo "extracts the dependencies from the compiler -v log and formats them "
        echo "in a make friendly way, given patterns together and excludes them"
        exit 0
        ;;
    --target)
        target=$1
        ;;
    *)
        break
        ;;
    esac
    shift
done

combPattern=
while [ $# -gt 0 ]
do
    if [ -z "$combPattern" ] ; then
        combPattern="$1"
    else
        combPattern="${combPattern}|$1"
    fi
    shift
done

if [ -n "$target" ] ; then
	echo "$target: \\"
fi

if [ -z "$combPattern" ] ; then
    sed -n 's/^ *import[	 ]*\([a-zA-Z_.0-9][a-zA-Z_.0-9]*\)[	 ].*.d\(i\{0,1\}\))\.*/\1.d\2 \\/p'
else
    sed -n 's/^ *import[	 ]*\([a-zA-Z_.0-9][a-zA-Z_.0-9]*\)[	 ].*.d\(i\{0,1\}\))\.*/\1.d\2 \\/p' | grep -v -E "$combPattern"
fi
echo
echo "# end"