#!/usr/bin/env bash
# this gives the objects to compile in a make compatible way
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

tool_dir=`dirname $0`
var_name="MODULES"
while [ $# -gt 0 ]
do
    case $1 in
        --help)
            echo "usage: mkMods.sh [--help] [--tool-dir tool_dir] [--out-var var_name] dir [exclude patterns]"
            echo "creates a list of the qualified names of D modules found in the"
            echo "directory dir excluding the given patterns."
            echo "The result is outputted as a make compatible assignement to the"
            echo "variable named var_name"
            echo "defaults: var_name=$var_name tool_dir=$tool_dir"
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

echo ${var_name}= \\
"$tool_dir/execOnFilteredFiles.sh" --skip-di "$tool_dir/modName2.sh" "$dir" $*
echo
echo "#end"
