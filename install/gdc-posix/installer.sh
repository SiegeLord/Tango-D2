die() {
    rm -rf /tmp/tango.installer.$$
    ERROR="$1"
    shift
    echo "$@"
    exit $ERROR
}

# Figure out our complete name
ORIGDIR=`pwd`
cd `dirname $0`
FULLNAME="`pwd`/`basename $0`"
cd $ORIGDIR

# Create our temporary directory
TTMP=/tmp/tango.installer.$$
mkdir -p $TTMP || die 1 "Failed to create temporary directory"

# This installer works by black magic: The following number must be the exact
# number of lines in this file+3:
LINES=88

# Install GDC if necessary
GDCDIR=
if [ "$INST_GDC" = "1" ]
then
    if [ ! "$1" ]
    then
        echo -n "What path do you want to install GDC to? "
        read GDCDIR
    else
        GDCDIR="$1"
    fi
    export PATH="$GDCDIR/bin:$PATH"
    mkdir -p $GDCDIR || die 1 "Failed to create the GDC install directory"
    cd $GDCDIR || die 1 "Failed to cd to the GDC install directory"
    tail -n+$LINES $FULLNAME | tar Oxf - gdc.tar.gz | gunzip -c | tar xf - ||
        die 1 "Failed to extract GDC"
fi

# Make sure GDC is installed
if [ ! "$GDCDIR" ]
then
    gdc --help > /dev/null 2> /dev/null
    if [ "$?" = "127" ]
    then
        echo -n "What path is GDC installed to? "
        read GDCDIR
        export PATH="$GDCDIR/bin:$PATH"
        if [ ! -e $GDCDIR/bin/gdc ]
        then
            die 1 "GDC is not installed to that path!"
        fi
    else
        # Get our proper GDC prefix
        for i in `echo $PATH | sed 's/:/ /g'`
        do
            if [ -e "$i/gdc" ]
            then
                GDCDIR="$i/.."
                break
            fi
        done
    fi
fi

# Then, cd to our tmpdir and extract core.tar.gz
cd $TTMP || die 1 "Failed to cd to temporary directory"

tail -n+$LINES $FULLNAME | tar Oxf - core.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract the Tango core"

# And install it
cd lib || die 1 "Tango core improperly archived"
# Just in case it's already installed, uninstall it
./install-gdc.sh --uninstall > /dev/null 2> /dev/null
./install-gdc.sh > /dev/null 2> /dev/null || die 1 "Failed to install Tango core"

# Then install the rest of Tango
cd $GDCDIR || die 1 "Failed to cd to GDC's installed prefix"
tail -n+$LINES $FULLNAME | tar Oxf - tango.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract Tango"

echo 'Done!'
exit 0
