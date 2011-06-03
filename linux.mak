CC = gcc
DMD = dmd
RM=rm -rf
CP=cp -v
CFLAGS = 
DFLAGS=-gc -unittest -debug -d
DOCDIR=doc/html

# CORE
SRC_CORE=tango/core/Array.d \
	tango/core/BitArray.d \
	tango/core/BitManip.d \
	tango/core/ByteSwap.d \
	tango/core/Exception.d \
	tango/core/sync/Mutex.d \
	tango/core/Traits.d \
	tango/stdc/errno.d \
	tango/stdc/stringz.d \
	tango/sys/Common.d

SRC_IO=tango/io/Console.d \
	tango/io/device/Array.d \
	tango/io/device/Conduit.d \
	tango/io/device/Device.d \
	tango/io/device/File.d \
	tango/io/model/IConduit.d \
	tango/io/Stdout.d \
	tango/io/stream/Buffered.d \
	tango/io/stream/Delimiters.d \
	tango/io/stream/Format.d \
	tango/io/stream/Iterator.d \
	tango/io/stream/Lines.d \
	tango/io/selector/model/ISelector.d \
	tango/io/selector/AbstractSelector.d \
	tango/io/selector/SelectorException.d \
	tango/io/selector/SelectSelector.d \
	tango/io/selector/PollSelector.d \
	tango/io/selector/EpollSelector.d
	
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
	tango/text/Util.d \
	tango/text/convert/Float.d \
	tango/text/convert/Integer.d \
	tango/text/convert/Layout.d \
	tango/text/convert/Utf.d \
	tango/text/convert/TimeStamp.d \
	tango/text/convert/Format.d \
	tango/text/xml/Document.d \
	tango/text/xml/PullParser.d

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

SRC_UTIL=tango/util/cipher/AES.d \
	tango/util/cipher/Blowfish.d \
	tango/util/cipher/ChaCha.d \
	tango/util/cipher/Cipher.d \
	tango/util/cipher/RC4.d \
	tango/util/cipher/RC6.d \
	tango/util/cipher/Salsa20.d \
	tango/util/cipher/TEA.d \
	tango/util/cipher/XTEA.d \
	tango/util/Convert.d \
	tango/util/MinMax.d \
	tango/util/compress/c/bzlib.d \
	tango/util/compress/c/zlib.d \
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
	tango/util/log/AppendConsole.d \
	tango/util/log/Log.d \
	tango/util/log/AppendFile.d \
	tango/util/log/Config.d \
	tango/util/log/Trace.d \
	tango/util/log/LayoutDate.d \
	tango/util/log/model/ILogger.d

	
SRC_NET=tango/net/device/Berkeley.d \
	tango/net/device/Socket.d \
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
	tango/net/http/model/HttpParamsView.d \
	tango/net/InternetAddress.d \
	tango/net/Uri.d \
	tango/net/model/UriView.d

#DIR_EXAMPLES=$(wildcard ./doc/example/*)
DIR_EXAMPLES=./doc/example/console ./doc/example/networking
SRC_EXAMPLES:=$(foreach DIR_EXAMPLE,$(DIR_EXAMPLES),$(wildcard $(DIR_EXAMPLE)/*.d))
PROG_EXAMPLES=$(SRC_EXAMPLES:%.d=%)

# generare src and obj
SRC=$(SRC_CORE) $(SRC_IO) $(SRC_MATH) $(SRC_TEXT) $(SRC_TIME) $(SRC_UTIL) $(SRC_NET)
OBJ=$(SRC:%.d=%.o)
HTML=$(SRC:%.d=%.html)

# targets
all: libtango2.a
		@echo "libtango2.a was build"

install: libtango2.a
		$(CP) libtango2.a /usr/lib
		
examples: $(PROG_EXAMPLES)
		@echo "all examples are made"
		
tests:
		
		
libtango2.a: $(OBJ)
		$(DMD) $(DFLAGS) -lib -oflibtango2.a $(OBJ)

doc: $(HTML)
		@echo "All docs are stored in $(DOCDIR)"

clean:
		$(RM) libtango2.a
		$(RM) $(OBJ)

%: %.d
		$(DMD) -of$@ $< $(DFLAGS) -L-ltango2

%.o:%.d
		$(DMD) -c -of$@ $< $(DFLAGS)

%.html:%.d
		$(DMD) -o- -Df$(DOCDIR)/$@ $<
