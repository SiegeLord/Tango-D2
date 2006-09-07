pushd ./compiler/gdc
./configure
popd

OLDHOME=$HOME
export HOME=`pwd`
make clean   -fgdc-posix.mak
make         -fgdc-posix.mak
make install -fgdc-posix.mak
make clean   -fgdc-posix.mak
export HOME=$OLDHOME
