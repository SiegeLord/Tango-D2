OLDHOME=$HOME
export HOME=`pwd`
make clean   -fdmd-posix.mak
make         -fdmd-posix.mak
make install -fdmd-posix.mak
make clean   -fdmd-posix.mak
export HOME=$OLDHOME
