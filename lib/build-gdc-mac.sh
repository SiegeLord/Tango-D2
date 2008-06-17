#!/bin/sh

FAILED=0
# Written by Anders F. Björklund
cd "`dirname \"$0\"`"

# set up symbolic links to compilers without version suffix

tempdir=/tmp/build-$$
for target in powerpc-apple-darwin8 i686-apple-darwin8; do
  for prefix in /usr /usr/local /opt/gdc /sw /opt/local; do
  if [ -x $prefix/bin/gdc ]; then
    version=`$prefix/bin/gdc -dumpversion`
    for program in gcc g++ gdc; do
    if [ ! -L "$prefix/bin/$target-$program" ]; then
      if [ -x "$prefix/bin/$target-$program-$version" ]; then
      echo "$target-$program -> $target-$program-$version"
      ln -s $prefix/bin/$target-$program-$version $tempdir/$target-$program
      fi
    fi
    done
  fi
  if [ -x "$prefix/bin/gdmd" ]; then
    for program in gdmd; do
    if [ ! -L "$prefix/bin/$target-$program" ]; then
      echo "$target-$program -> $program"
      ln -s $prefix/bin/$program $tempdir/$target-$program
    fi
    done
  fi
  done
done
export PATH="$tempdir:$PATH"

# build Universal Binary versions of the Tango libraries

export MAKETOOL=make

HOME=`pwd` make -s clean -fgdc-posix.mak

LIBS="common/libtango-cc-tango.a gc/libtango-gc-basic.a libgphobos.a"

for lib in $LIBS; do test -r $lib && rm $lib; done

if ./build-gdc-x.sh powerpc-apple-darwin8 1>&2
then
    for lib in $LIBS; do mv $lib $lib.ppc; done
else
    FAILED=1
fi

if [ "$FAILED" = "0" ]
then
    if ./build-gdc-x.sh i686-apple-darwin8 1>&2
    then
        for lib in $LIBS; do mv $lib $lib.i386; done
    else
        FAILED=1
    fi
fi

if [ "$FAILED" = "1" ]
then
    echo 'Failed to build universal binaries. Trying GDC.'
    ./build-gdc.sh
else
    for lib in $LIBS; do \
    lipo -create -output $lib $lib.ppc $lib.i386; done
fi
