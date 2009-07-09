#!/bin/bash
# finds d files in the directory give as first argument, excluding paths that
# match the following arguments
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

dfiles="\\( -name '*.d' -o -name '*.di' \\)"
while [ $# -gt 0 ]
do
    case $1 in
        --help)
            echo "usage: execOnFilteredFiles.sh [--help] [--tool-dir tool_dir] [--skip-di] cmd dir [exclude patterns]"
            echo "evaluates cmd on the filtered files, some batch of them together"
            echo "if --skip-di is given di (interface) files are skipped"
            echo "defaults: tool_dir=$tool_dir"
            exit 0
            ;;
        --skip-di)
            dfiles="-name '*.d' "
            ;;
        --tool-dir)
            shift
            tool_dir=$1
            ;;
        --out-var)
            shift
            var_name=$1
            ;;
        *)
            break
            ;;
    esac
    shift
done

execCmd=$1
shift
if [ -z "$execCmd" ] ; then
    execCmd=echo
fi
dir=$1
shift
if [ -z "$dir" ] ; then
    dir=.
fi

excl=
while [ $# -gt 0 ]
do
    # -false is a non standard linux extension
    excl="$excl -path '$1' -prune -name a -not -name a -o "
    shift
done
if ( uname -m | grep -i mingw >& /dev/null ) ; then 
    findCmd="find '$dir' $excl $dfiles -exec $execCmd '{}' \;"
else
    findCmd="find '$dir' $excl $dfiles -exec $execCmd '{}' \+"
fi
sh -c "$findCmd"
