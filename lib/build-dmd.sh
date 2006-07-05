OLDHOME=$HOME
export HOME=`pwd`
make clean   -fdmd-linux.mak
make         -fdmd-linux.mak
make install -fdmd-linux.mak
make clean   -fdmd-linux.mak
export HOME=$OLDHOME
