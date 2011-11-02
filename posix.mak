# Copyright (c) 2011 Kris Bell. All rights reserved
# BSD style: $(LICENSE)
# Okt 2011: Initial release

#
# NOTICE: This file needs the gnu make, gmake on bsd platform.
#

# ==================== config section ========================
CC = gcc
DMD = dmd
RM=rm -rf
CP=cp -v
MODEL=
CFLAGS= 
DFLAGS=-I../druntime/import -w -d
LFLAGS=../druntime/lib/libdruntime.a
DOCDIR=doc/html
MAKEFILE:=$(lastword $(MAKEFILE_LIST))
# ============================================================


# ==================== source files ==========================
SRC_CORE=tango/core/Array.d \
	tango/core/BitArray.d \
	tango/core/ByteSwap.d \
	tango/core/Exception.d \
	tango/core/RuntimeTraits.d \
	tango/core/Traits.d \
	tango/core/Thread.d \
	tango/core/Variant.d \
	tango/core/Version.d \
	\
	tango/sys/Environment.d \
	tango/sys/Common.d \
	tango/sys/Pipe.d \
	tango/sys/Process.d \
	tango/sys/consts/socket.d \
	tango/sys/linux/consts/socket.d \
	tango/sys/linux/consts/fcntl.d

SRC_IO=tango/io/Console.d \
	tango/io/Stdout.d \
	tango/io/File.d \
	tango/io/FilePath.d \
	tango/io/FileScan.d \
	tango/io/Path.d \
	\
	tango/io/device/Array.d \
	tango/io/device/Conduit.d \
	tango/io/device/Device.d \
	tango/io/device/FileMap.d \
	\
	tango/io/model/IConduit.d \
	tango/io/model/ISelectable.d \
	\
	tango/io/selector/model/ISelector.d \
	tango/io/selector/AbstractSelector.d \
	tango/io/selector/SelectorException.d \
	tango/io/selector/SelectSelector.d \
	tango/io/selector/PollSelector.d \
	tango/io/selector/EpollSelector.d \
	tango/io/selector/Selector.d \
	\
	tango/io/stream/Buffered.d \
	tango/io/stream/Delimiters.d \
	tango/io/stream/Digester.d \
	tango/io/stream/Format.d \
	tango/io/stream/Iterator.d \
	tango/io/stream/Lines.d \
	tango/io/stream/Zlib.d \
	\
	tango/io/vfs/FileFolder.d \
	tango/io/vfs/model/Vfs.d
	
SRC_BINDING=tango/binding/bzlib.d \
	tango/binding/zlib.d

SRC_MATH=tango/math/Bessel.d \
	tango/math/BigInt.d \
	tango/math/Bracket.d \
	tango/math/Elliptic.d \
	tango/math/ErrorFunction.d \
	tango/math/GammaFunction.d \
	tango/math/IEEE.d \
	tango/math/internal/BignumNoAsm.d \
	tango/math/internal/BignumX86.d \
	tango/math/internal/BiguintCore.d \
	tango/math/Math.d \
	tango/math/Probability.d \
	tango/math/random/engines/ArraySource.d \
	tango/math/random/engines/CMWC.d \
	tango/math/random/engines/KissCmwc.d \
	tango/math/random/engines/KISS.d \
	tango/math/random/engines/Sync.d \
	tango/math/random/engines/Twister.d \
	tango/math/random/engines/URandom.d \
	tango/math/random/ExpSource.d \
	tango/math/random/Kiss.d \
	tango/math/random/NormalSource.d \
	tango/math/random/Random.d \
	tango/math/random/Twister.d \
	tango/math/random/Ziggurat.d
	
SRC_TEXT=tango/text/Ascii.d \
	tango/text/Arguments.d \
	tango/text/Stringz.d \
	tango/text/Unicode.d \
	tango/text/UnicodeData.d \
	tango/text/Util.d \
	\
	tango/text/json/JsonEscape.d \
	tango/text/json/JsonParser.d \
	tango/text/json/Json.d \
	\
	tango/text/convert/Float.d \
	tango/text/convert/Integer.d \
	tango/text/convert/Layout.d \
	tango/text/convert/Utf.d \
	tango/text/convert/TimeStamp.d \
	tango/text/convert/Format.d \
	\
	tango/text/locale/Convert.d \
	tango/text/locale/Core.d \
	tango/text/locale/Data.d \
	tango/text/locale/Locale.d \
	tango/text/locale/Posix.d \
	\
	tango/text/xml/Document.d \
	tango/text/xml/DocPrinter.d \
	tango/text/xml/PullParser.d \
	tango/text/xml/SaxParser.d

SRC_TIME=tango/time/chrono/Calendar.d \
	tango/time/chrono/GregorianBased.d \
	tango/time/chrono/Gregorian.d \
	tango/time/chrono/Hebrew.d \
	tango/time/chrono/Hijri.d \
	tango/time/chrono/Japanese.d \
	tango/time/chrono/Korean.d \
	tango/time/chrono/Taiwan.d \
	tango/time/chrono/ThaiBuddhist.d \
	tango/time/Clock.d \
	tango/time/ISO8601.d \
	tango/time/StopWatch.d \
	tango/time/Time.d \
	tango/time/WallClock.d

SRC_UTIL=tango/util/Convert.d \
	tango/util/MinMax.d \
	\
	tango/util/container/more/Stack.d \
	tango/util/container/Container.d \
	tango/util/container/LinkedList.d \
	\
	tango/util/compress/Zip.d \
	\
	tango/util/cipher/AES.d \
	tango/util/cipher/Blowfish.d \
	tango/util/cipher/ChaCha.d \
	tango/util/cipher/Cipher.d \
	tango/util/cipher/RC4.d \
	tango/util/cipher/RC6.d \
	tango/util/cipher/Salsa20.d \
	tango/util/cipher/TEA.d \
	tango/util/cipher/XTEA.d \
	\
	tango/util/digest/Digest.d \
	tango/util/digest/Crc32.d \
	tango/util/digest/MerkleDamgard.d \
	tango/util/digest/Md2.d \
	tango/util/digest/Md4.d \
	tango/util/digest/Md5.d \
	tango/util/digest/Ripemd128.d \
	tango/util/digest/Ripemd160.d \
	tango/util/digest/Ripemd256.d \
	tango/util/digest/Ripemd320.d \
	tango/util/digest/Sha01.d \
	tango/util/digest/Sha0.d \
	tango/util/digest/Sha1.d \
	tango/util/digest/Sha256.d \
	tango/util/digest/Sha512.d \
	tango/util/digest/Whirlpool.d \
	tango/util/digest/Tiger.d \
	\
	tango/util/encode/Base64.d \
	tango/util/encode/Base32.d \
	tango/util/encode/Base16.d \
	\
	tango/util/log/AppendConsole.d \
	tango/util/log/AppendFile.d \
	tango/util/log/AppendSocket.d \
	tango/util/log/LayoutChainsaw.d \
	tango/util/log/Log.d \
	tango/util/log/Config.d \
	tango/util/log/Trace.d \
	tango/util/log/LayoutDate.d \
	tango/util/log/model/ILogger.d

SRC_NET=tango/net/Uri.d \
	tango/net/Socket.d \
	tango/net/SocketSet.d \
	tango/net/NetHost.d \
	tango/net/Address.d \
	tango/net/InternetAddress.d \
	tango/net/Internet6Address.d \
	tango/net/LocalAddress.d \
	tango/net/LocalSocket.d \
	tango/net/LocalServer.d \
	tango/net/TcpSocket.d \
	tango/net/TcpServer.d \
	tango/net/UdpSocket.d \
	tango/net/UdpServer.d \
	tango/net/Multicast.d \
	\
	tango/net/http/ChunkStream.d \
	tango/net/http/HttpCookies.d \
	tango/net/http/HttpHeaders.d \
	tango/net/http/HttpPost.d \
	tango/net/http/HttpTokens.d \
	tango/net/http/HttpClient.d \
	tango/net/http/HttpConst.d \
	tango/net/http/HttpGet.d \
	tango/net/http/HttpParams.d \
	tango/net/http/HttpStack.d \
	tango/net/http/HttpTriplet.d \
	tango/net/http/model/HttpParamsView.d
	
SRC_SQL=tango/sql/Mysql.d

# For now, 32 bit is the default model
ifeq (,$(MODEL))
        MODEL:=32
endif

# Set correct d Build flags
ifeq ($(BUILD),debug)
	DFLAGS += -m$(MODEL) -g -debug
else
	ifeq ($(BUILD),unittest)
			DFLAGS += -m$(MODEL) -g -debug -debug=UnitTest -unittest
	else
		DFLAGS += -m$(MODEL) -O -release -nofloat
	endif
endif

# generate all target for the examles
#DIR_EXAMPLES=$(wildcard ./doc/example/*) uncomment when all examples work!
# ./doc/example/conduits <-- not all of them convered
DIR_EXAMPLES=./doc/example/concurrency ./doc/example/conduits ./doc/example/text ./doc/example/console ./doc/example/networking ./doc/example/sql ./doc/example/system ./doc/example/traits
SRC_EXAMPLES:=$(foreach DIR_EXAMPLE,$(DIR_EXAMPLES),$(wildcard $(DIR_EXAMPLE)/*.d))
PROG_EXAMPLES=$(SRC_EXAMPLES:%.d=%)

# generare src obj and html for all tango files
ROOT=generated/$(BUILD)/$(MODEL)
SRC=$(SRC_CORE) $(SRC_IO) $(SRC_BINDING) $(SRC_MATH) $(SRC_TEXT) $(SRC_TIME) $(SRC_UTIL) $(SRC_NET) $(SRC_SQL)
OBJ=$(addprefix $(ROOT)/, $(SRC:%.d=%.o))
HTML=$(addprefix $(DOCDIR)/, $(SRC:%.d=%.html))

# generate unittest and filter-out those that don't pass unittest for now
EXCLUDED_UNITTEST=tango/sql/Mysql.d tango/text/convert/TimeStamp.d
SRC_UNITTESTS=$(filter-out $(EXCLUDED_UNITTEST),$(SRC))
UNITTESTS=$(addprefix $(ROOT)/unittest/,$(SRC_UNITTESTS:%.d=%))

# ==================== end user targets ========================
ifeq ($(BUILD),)
release:
		$(MAKE) MODEL=$(MODEL) BUILD=release --no-print-directory -f $(MAKEFILE)
debug:
		$(MAKE) MODEL=$(MODEL) BUILD=debug --no-print-directory -f $(MAKEFILE)
unittest:
		$(MAKE) unittest MODEL=$(MODEL) BUILD=debug --no-print-directory -f $(MAKEFILE)
		$(MAKE) unittest MODEL=$(MODEL) BUILD=release --no-print-directory -f $(MAKEFILE)
install:
		$(MAKE) install MODEL=$(MODEL) BUILD=release --no-print-directory -f $(MAKEFILE)
else
all: $(ROOT)/libtango2.a
		@echo "========================================================================="
		@echo "= $(ROOT)/libtango2.a was successfully generated."
		@echo "========================================================================="

unittest: $(UNITTESTS)
		@echo "All unittests in $(BUILD) mode were executed."

install: all
		$(CP) $(ROOT)/libtango2.a /usr/lib$(MODEL)
		@echo "install was done."
endif

examples: $(PROG_EXAMPLES)
		@echo "all examples are made"

doc: $(HTML)
		@echo "All docs are stored in $(DOCDIR)"

clean:
		$(RM) generated
		$(RM) unittest
		$(RM) $(DOCDIR)
		$(RM) $(PROG_EXAMPLES)

# ==================== target pattern ========================
# used for generating unittest (- means go ahead on errors).
$(ROOT)/unittest/%:%.d
		@echo "$(MODEL) Bit $(BUILD) Unittest - Testing $< -> $@ ..."
		-@$(DMD) -m$(MODEL) $(DFLAGS) -unittest -debug -debug=UnitTest -of$@ $< unittest.d
		-@$@
		-@touch -t 197001230123 $@

# generate library of all source file
$(ROOT)/libtango2.a: $(OBJ)
		$(DMD) $(DFLAGS) $(LFLAGS) -lib -of$@ $(OBJ)

# generate object file from source file
$(ROOT)/%.o:%.d
		$(DMD) -c -m$(MODEL) $(DFLAGS) -of$@ $<

# generate documentation of source file
$(DOCDIR)/%.html:%.d
		$(DMD) -o- -version=TangoDoc -Df$@ $<

# generate examples
%: %.d
		$(DMD) -m$(MODEL) -of$@ $< -L-ltango2
