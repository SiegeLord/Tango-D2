OLDHOME=$HOME
export HOME=`pwd`
make clean lib doc install clean -fdmd-posix.mak
export HOME=$OLDHOME
