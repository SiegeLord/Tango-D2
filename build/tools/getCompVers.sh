#!/usr/bin/env bash
# returns the compiler name and version name out of an IDENT string
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

compiler=1
version=1
while [ $# -gt 0 ]
do
    case $1 in
        --help)
            echo "usage: $0 [--help] [--compiler] [--version] ident_string"
            echo "returns the compiler name and version name out of an IDENT string"
            echo "(and IDENT string has the following structure os-platform-compiler-version)"
            echo "by default returns only compiler if version is opt and compiler-version"
            echo "if the version is different, if --compiler or --version are given"
            echo "only the compiler, only the version of compiler-version are returned"
            exit 0
            ;;
        --compiler)
            shift
            compiler=2
            if [ "version" == "1" ] ; then version=0; fi
            ;;
        --version)
            shift
            version=2
            if [ "compiler" == "1" ] ; then compiler=0; fi
            ;;
        *)
            break
            ;;
    esac
    shift
done

comp=`echo $1 | sed 's/.*-\([^-]*\)-[^-][^-]*$/\1/'`
vers=`echo $1 | sed 's/.*-[^-]*-\([^-][^-]*\)$/\1/'`
if [ "$vers" == "opt" -a "$version" == "1" ] ; then
    echo $comp
else
    if [ $version -gt 0 -a $compiler -gt 0 ] ; then
        echo ${comp}-${vers}
    elif [ $compiler -gt 0 ] ; then
        echo ${comp}
    elif [ $version -gt 0 ] ; then
        echo ${vers}
    fi
fi