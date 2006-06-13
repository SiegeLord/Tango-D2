export TANGO_OLDHOME=$HOME
export HOME=`pwd`
make -f linux.mak clean
make -f linux.mak
make -f linux.mak install
make -f linux.mak clean
export HOME=$TANGO_OLDHOME
