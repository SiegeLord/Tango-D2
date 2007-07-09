OLDHOME=$HOME
export HOME=`pwd`
make clean -fdmd-posix.mak
make lib doc install -fdmd-posix.mak
make clean -fdmd-posix.mak
export HOME=$OLDHOME
chmod 644 ../tango/core/*.di
