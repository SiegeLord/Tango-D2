#!/usr/bin/env bash
# this gives make rules to generate the intermediate d files that have 
# a fully qualifed name
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

tool_dir=`dirname $0`
while [ $# -gt 0 ]
do
    case $1 in
        --help)
            echo "usage: mkIntermediate.sh [--help] [--tool-dir tool_dir] dir [exclude patterns]"
            echo "generates the list of rules needed to generate intermediate d"
            echo "files with fully qualified name"
            echo "defaults: tool_dir=$tool_dir"
            exit 0
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

dir=$1
shift
if [ -z "$dir" ] ; then
    dir=.
fi

"$tool_dir/execOnFilteredFiles.sh" "$tool_dir/dep0.sh" "$dir" $*
