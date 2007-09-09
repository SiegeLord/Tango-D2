OLDHOME=$HOME
export HOME=`pwd`

goerror(){
    export HOME=$OLDHOME
    echo "="
    echo "= *** Error ***"
    echo "="
    exit 1
}

make clean -fdmd-posix.mak           || goerror
make lib doc install -fdmd-posix.mak || goerror
make clean -fdmd-posix.mak           || goerror
chmod 644 ../tango/core/*.di         || goerror

export HOME=$OLDHOME

