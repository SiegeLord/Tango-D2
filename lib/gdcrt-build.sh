OLDHOME=$HOME
export HOME=`pwd`
./compiler/gdc/configure
make
export HOME=$OLDHOME
