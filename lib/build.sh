OLDHOME=$HOME
export HOME=`pwd`
make clean   -flinux.mak
make         -flinux.mak
make install -flinux.mak
make clean   -flinux.mak
export HOME=$OLDHOME
