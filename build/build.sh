#!/bin/bash
# builds runtime & tango-user
# tango 

die() {
    echo "$1"
    exit $2
}

tango_home=`dirname $0`
if [ "." == "$tango_home" ] ; then
    tango_home=`pwd`
    tango_home=`dirname $tango_home`
elif [ -d "`dirname $tango_home`" ] ; then
    tango_home=`dirname $tango_home`
else
    tango_home=`pwd`
fi
quick=
version=
user_only=
no_install=
lib_install_dir=
clean_only=
silent="-s"
while [ $# -gt 0 ]
do
    case $1 in
        --help)
            echo "usage: build.sh [--help] [--tango-home path/to/tango_root]"
            echo "[--quick] [--version versionName] [--user-only] [--no-install-libs]"
            echo "[--lib-install-dir path/to/lib/install/dir] [--verbose] [--clean]"
            echo
            echo "Builds tango runtime and tango user libs, by default makes"
            echo "a distclean and builds opt, dbg and tst versions."
            echo "If --version X is passed only version X will be built."
            echo "--clean removes all build files"
            echo "--quick does not clean before building"
            echo "--user-only rebuilds only the user lib"
            echo "--no-install-libs skips the installation of the libs"
            echo "with --verbose make commands print all commands"
            echo "the script uses '$'DC as compiler if set, or the first"
            echo "compiler found if not set"
            exit 0
            ;;
        --quick)
            quick=1
            ;;
        --user-only)
            user_only=1
            ;;
        --tango-home)
            shift
            tango_home=$1
            ;;
        --version)
            shift
            version=$1
            ;;
        --lib-install-dir)
            shift
            lib_install_dir=$1
            ;;
        --no-install-libs)
            no_install=1
            ;;
        --clean)
            clean_only=1
            ;;
        --verbose)
            silent=
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ -z "$user_only" ] ; then
    cd $tango_home/build/runtime
    if [ -n "$clean_only" ] ; then
        make $silent distclean || die "error cleaning runtime" 1
    else
        if [ -z "$quick" ] ; then
            make $silent distclean || die "error cleaning runtime" 1
        fi
        if [ -z "$version" ] ; then
            make $silent allVersions || die "error building runtime" 2
        else
            make $silent VERSION=$version
        fi
    fi
    cd ../..
fi
cd $tango_home/build/user
if [ -n "$clean_only" ] ; then
    make $silent distclean || die "error cleaning runtime" 1
else
    if [ -z "$quick" ] ; then
        make $silent distclean || die "error cleaning tango user" 3
    fi
    if [ -z "$version" ] ; then
        make $silent allVersions || die "error building tango user" 4
    else
        make $silent VERSION=$version
    fi
fi
cd ../..

if [ -z "$user_only" ] ; then
    echo "built tango-base and tango-user, libs in"
else
    echo "built tango-user, libs in"
fi
echo "  $tango_home/build/libs"

if [ -z "$no_install" ] ; then
    DC_SHORT=`$tango_home/build/tools/guessCompiler.sh $DC`
    if [ -z "$lib_install_dir" ] ; then
        comp_path=`$tango_home/build/tools/guessCompiler.sh --path $DC`
        lib_install_dir=`dirname "$comp_path"`
        lib_install_dir=`dirname "$lib_install_dir"`/lib
    fi
    if [ -d "$lib_install_dir" ] ; then
        echo "build/libs/libtango*${DC_SHORT}* ->  $lib_install_dir"
        cp $tango_home/build/libs/*tango*${DC_SHORT}* $lib_install_dir
    else
        echo "ERROR, invalid library installation directory:"
        echo " $lib_install_dir"
        echo "installation skipped, you can pass an explicit path "
        echo "with --lib-install-dir"
    fi
fi

echo "to use tango link them and make sure that the compiler has"
echo "  -I$tango_home/user"
echo "in its settings, or copy the content of"
echo "  $tango_home/user"
echo "to a directory in the include path of the compiler"
