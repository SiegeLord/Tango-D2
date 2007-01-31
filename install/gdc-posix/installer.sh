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
# number of lines in this file+4:
LINES=64

# Make sure GDC is installed
gdc --help > /dev/null 2> /dev/null
if [ "$?" = "127" ]
then
    echo -n "What path is GDC installed to? "
    read GDCDIR
    export PATH="$GDCPATH/bin:$PATH"
    if [ ! -e $GDCPATH/bin/gdc ]
    then
        die 1 "GDC is not installed to that path!"
    fi
else
    # Get our proper GDC prefix
    GDCDIR="`/opt/gdc/bin/gdc -print-search-dirs | grep '^install:' | sed 's/install: //'`/../../../.."
fi

# Then, cd to our tmpdir and extract core.tar.gz
cd $TTMP || die 1 "Failed to cd to temporary directory"

tail +$LINES $FULLNAME | tar Oxf - core.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract the Tango core"

# And install it
cd lib || die 1 "Tango core improperly archived"
# Just in case it's already installed, uninstall it
./install-gdc.sh --uninstall > /dev/null 2> /dev/null
./install-gdc.sh > /dev/null 2> /dev/null || die 1 "Failed to install Tango core"

# Then install the rest of Tango
cd $GDCDIR || die 1 "Failed to cd to GDC's installed prefix"
tail +$LINES $FULLNAME | tar Oxf - tango.tar.gz | gunzip -c | tar xf - ||
    die 1 "Failed to extract Tango"

echo 'Done!'
echo 'If at any time you wish to uninstall Tango:'
echo ' $ dsss uninstall tango'
echo ' $ uninstall-tango-core'
exit 0
