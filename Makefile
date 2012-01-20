
export PROJECT_NAME     = tango
export AUTHOR           = SiegeLord
export DESCRIPTION      =
export VERSION          = 2
export LICENSE          = ACL v3
SOURCES                 = tango/core/Array.d                    tango/core/BitManip.d                   tango/core/ByteSwap.d                   \
                          tango/core/Exception.d                tango/core/Memory.d                     tango/core/Octal.d                      \
                          tango/core/sync/Atomic.d              tango/core/Thread.d                     tango/core/Traits.d                     \
                          tango/core/Vararg.d                   tango/core/Tuple.d                      tango/io/Console.d                      \
                          tango/io/device/Array.d               tango/io/device/Conduit.d               tango/io/device/Device.d                \
                          tango/io/device/File.d                tango/io/device/FileMap.d               tango/io/model/IConduit.d               \
                          tango/io/model/IFile.d                tango/io/FilePath.d                     tango/io/Path.d                         \
                          tango/io/Stdout.d                     tango/io/stream/Buffered.d              tango/io/stream/Delimiters.d            \
                          tango/io/stream/Iterator.d            tango/io/stream/Format.d                tango/io/stream/Lines.d                 \
                          tango/io/stream/Zlib.d                tango/io/stream/Digester.d              tango/math/Bessel.d                     \
                          tango/math/BigInt.d                   tango/math/Bracket.d                    tango/math/Elliptic.d                   \
                          tango/math/ErrorFunction.d            tango/math/GammaFunction.d              tango/math/IEEE.d                       \
                          tango/math/internal/BignumNoAsm.d     tango/math/internal/BignumX86.d         tango/math/internal/BiguintCore.d       \
                          tango/math/Math.d                     tango/math/Probability.d                tango/math/random/engines/ArraySource.d \
                          tango/math/random/engines/CMWC.d      tango/math/random/engines/KissCmwc.d    tango/math/random/engines/KISS.d        \
                          tango/math/random/engines/Sync.d      tango/math/random/engines/Twister.d     tango/math/random/engines/URandom.d     \
                          tango/math/random/ExpSource.d         tango/math/random/Kiss.d                tango/math/random/NormalSource.d        \
                          tango/math/random/Random.d            tango/math/random/Twister.d             tango/math/random/Ziggurat.d            \
                          tango/net/device/Berkeley.d           tango/net/device/Datagram.d             tango/net/device/Socket.d               \
                          tango/net/device/LocalSocket.d        tango/net/device/Multicast.d            tango/net/InternetAddress.d             \
                          tango/net/Uri.d                       tango/net/model/UriView.d               tango/net/util/c/OpenSSL.d              \
                          tango/net/http/HttpClient.d           tango/net/http/HttpConst.d              tango/net/http/HttpCookies.d            \
                          tango/net/http/HttpGet.d              tango/net/http/HttpHeaders.d            tango/net/http/HttpParams.d             \
                          tango/net/http/HttpPost.d             tango/net/http/HttpStack.d              tango/net/http/HttpTokens.d             \
                          tango/net/http/HttpTriplet.d          tango/net/http/model/HttpParamsView.d   tango/stdc/config.d                     \
                          tango/stdc/errno.d                    tango/stdc/stdarg.d                     tango/stdc/stringz.d                    \
                          tango/stdc/time.d                     tango/stdc/stddef.d                     tango/stdc/stdint.d                     \
                          tango/stdc/signal.d                   tango/stdc/inttypes.d                   tango/stdc/string.d                     \
                          tango/stdc/ctype.d                    tango/stdc/stdlib.d                     tango/stdc/stdio.d                      \
                          tango/stdc/math.d                     tango/stdc/locale.d                     tango/stdc/posix/inttypes.d             \
                          tango/stdc/posix/dirent.d             tango/stdc/posix/langinfo.d             tango/stdc/posix/signal.d               \
                          tango/stdc/posix/dlfcn.d              tango/stdc/posix/fcntl.d                tango/stdc/posix/poll.d                 \
                          tango/stdc/posix/pwd.d                tango/stdc/posix/time.d                 tango/stdc/posix/unistd.d               \
                          tango/stdc/posix/utime.d              tango/stdc/posix/pthread.d              tango/stdc/posix/sched.d                \
                          tango/stdc/posix/stdlib.d             tango/stdc/posix/semaphore.d            tango/stdc/posix/sys/select.d           \
                          tango/stdc/posix/sys/stat.d           tango/stdc/posix/sys/types.d            tango/stdc/posix/sys/time.d             \
                          tango/stdc/posix/sys/mman.d           tango/stdc/posix/sys/wait.d             tango/sys/Common.d                      \
                          tango/sys/Pipe.d                      tango/sys/Process.d                     tango/sys/SharedLib.d                   \
                          tango/sys/Environment.d               tango/sys/consts/fcntl.d                tango/sys/consts/unistd.d               \
                          tango/sys/consts/errno.d              tango/sys/consts/socket.d                                                       \
                          tango/text/Util.d                     tango/text/Search.d                     tango/text/Text.d                       \
                          tango/text/Unicode.d                  tango/text/UnicodeData.d                tango/text/convert/DateTime.d           \
                          tango/text/convert/Float.d            tango/text/convert/Format.d             tango/text/convert/Integer.d            \
                          tango/text/convert/Layout.d           tango/text/convert/Utf.d                tango/text/convert/TimeStamp.d          \
                          tango/text/convert/UnicodeBom.d       tango/text/json/Json.d                  tango/text/json/JsonEscape.d            \
                          tango/text/json/JsonParser.d          tango/text/locale/Collation.d           tango/text/locale/Convert.d             \
                          tango/text/locale/Core.d              tango/text/locale/Data.d                tango/text/locale/Locale.d              \
                          tango/text/locale/Parse.d             tango/text/locale/Posix.d               tango/text/locale/Win32.d               \
                          tango/text/xml/DocEntity.d            tango/text/xml/DocPrinter.d             tango/text/xml/DocTester.d              \
                          tango/text/xml/Document.d             tango/text/xml/PullParser.d             tango/text/xml/SaxParser.d              \
                          tango/time/chrono/Calendar.d          tango/time/chrono/GregorianBased.d      tango/time/chrono/Gregorian.d           \
                          tango/time/chrono/Hebrew.d            tango/time/chrono/Hijri.d               tango/time/chrono/Japanese.d            \
                          tango/time/chrono/Korean.d            tango/time/chrono/Taiwan.d              tango/time/chrono/ThaiBuddhist.d        \
                          tango/time/Clock.d                    tango/time/ISO8601.d                    tango/time/StopWatch.d                  \
                          tango/time/Time.d                     tango/time/WallClock.d                  tango/util/cipher/AES.d                 \
                          tango/util/cipher/Blowfish.d          tango/util/cipher/ChaCha.d              tango/util/cipher/Cipher.d              \
                          tango/util/cipher/RC4.d               tango/util/cipher/RC6.d                 tango/util/cipher/Salsa20.d             \
                          tango/util/cipher/TEA.d               tango/util/cipher/XTEA.d                tango/util/compress/c/bzlib.d           \
                          tango/util/compress/c/zlib.d          tango/util/compress/Zip.d               tango/util/container/CircularList.d     \
                          tango/util/container/Clink.d          tango/util/container/Container.d        tango/util/container/HashMap.d          \
                          tango/util/container/HashSet.d        tango/util/container/LinkedList.d       tango/util/container/model/IContainer.d \
                          tango/util/container/more/BitSet.d    tango/util/container/more/CacheMap.d    tango/util/container/more/HashFile.d    \
                          tango/util/container/more/Heap.d      tango/util/container/more/Stack.d       tango/util/container/more/StackMap.d    \
                          tango/util/container/more/Vector.d    tango/util/container/RedBlack.d         tango/util/container/Slink.d            \
                          tango/util/container/SortedMap.d      tango/util/Convert.d                    tango/util/digest/Crc32.d               \
                          tango/util/digest/Digest.d            tango/util/digest/Md2.d                 tango/util/digest/Md4.d                 \
                          tango/util/digest/Md5.d               tango/util/digest/MerkleDamgard.d       tango/util/digest/Ripemd128.d           \
                          tango/util/digest/Ripemd160.d         tango/util/digest/Ripemd256.d           tango/util/digest/Ripemd320.d           \
                          tango/util/digest/Sha01.d             tango/util/digest/Sha0.d                tango/util/digest/Sha1.d                \
                          tango/util/digest/Sha256.d            tango/util/digest/Sha512.d              tango/util/digest/Tiger.d               \
                          tango/util/digest/Whirlpool.d         tango/util/encode/Base16.d              tango/util/encode/Base32.d              \
                          tango/util/encode/Base64.d            tango/util/log/AppendConsole.d          tango/util/log/AppendFile.d             \
                          tango/util/log/AppendFiles.d          tango/util/log/Config.d                 tango/util/log/LayoutDate.d             \
                          tango/util/log/Log.d                  tango/util/log/Trace.d                  tango/util/log/model/ILogger.d          \
                          tango/util/MinMax.d                   tango/util/uuid/NamespaceGenV3.d        tango/util/uuid/NamespaceGenV5.d        \
                          tango/util/uuid/RandomGen.d           tango/util/uuid/Uuid.d                  tango/core/sync/ReadWriteMutex.d        \
                          tango/core/sync/Config.d              tango/core/sync/Semaphore.d             tango/core/sync/Condition.d             \
                          tango/core/sync/Mutex.d
ifeq ($(OS),"Windows")
    SOURCES            += tango/sys/win32/Types.d               tango/sys/win32/UserGdi.d               tango/sys/win32/WsaSock.d               \
                          tango/sys/win32/consts/socket.d       tango/sys/win32/consts/errno.d          tango/sys/win32/consts/fcntl.d          \
                          tango/sys/win32/consts/unistd.d       tango/text/Arguments.d                  tango/text/Ascii.d
else ifeq ($(OS),"Linux")
    SOURCES            += tango/sys/linux/epoll.d               tango/sys/linux/consts/fcntl.d          tango/sys/linux/consts/unistd.d         \
                          tango/sys/linux/consts/errno.d        tango/sys/linux/consts/socket.d         tango/sys/linux/linux.d
else ifeq ($(OS),"Darwin")
    SOURCES            += tango/sys/darwin/consts/fcntl.d       tango/sys/darwin/consts/machine.d       tango/sys/darwin/consts/socket.d        \
                          tango/sys/darwin/consts/sysctl.d      tango/sys/darwin/consts/unistd.d        tango/sys/darwin/darwin.d               \
                          tango/sys/darwin/consts/errno.d
else ifeq ($(OS),"Freebsd")
    SOURCES            += tango/sys/freebsd/consts/errno.d      tango/sys/freebsd/consts/fcntl.d        tango/sys/freebsd/consts/socket.d       \
                          tango/sys/freebsd/consts/sysctl.d     tango/sys/freebsd/consts/unistd.d       tango/sys/freebsd/freebsd.d
else ifeq ($(OS),"Solaris")
    SOURCES            += tango/sys/solaris/consts/errno.d      tango/sys/solaris/consts/fcntl.d        tango/sys/solaris/consts/socket.d       \
                          tango/sys/solaris/consts/sysctl.d     tango/sys/solaris/consts/unistd.d       tango/sys/solaris/solaris.d
endif

DDOCFILES               =

# include some command
include command.make

OBJECTS             = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o,    $(SOURCES))
PICOBJECTS          = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.pic.o,$(SOURCES))
HEADERS             = $(patsubst %.d,$(IMPORT_PATH)$(PATH_SEP)%.di,  $(SOURCES))
DOCUMENTATIONS      = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
DDOCUMENTATIONS     = $(patsubst %.d,$(DDOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))
define make-lib
	$(MKDIR) $(DLIB_PATH)
	$(AR) rcs $(DLIB_PATH)$(PATH_SEP)$@ $^
	$(RANLIB) $(DLIB_PATH)$(PATH_SEP)$@
endef

############# BUILD #############
all: static-lib header doc pkgfile
	@echo ------------------ Building $^ done

.PHONY : pkgfile
.PHONY : doc
.PHONY : ddoc
.PHONY : clean

static-lib: $(LIBNAME)

shared-lib: $(SONAME)

header: $(HEADERS)

doc: $(DOCUMENTATIONS)
	@echo ------------------ Building Doc done

ddoc: $(DDOCUMENTATIONS)
	$(DC) $(DDOC_FLAGS) index.d $(DF)$(DDOC_PATH)$(PATH_SEP)index.html
	@echo ------------------ Building DDoc done

geany-tag:
	@echo ------------------ Building geany tag
	$(MKDIR) geany_config
	geany -c geany_config -g $(PROJECT_NAME).d.tags $(SOURCES)

pkgfile:
	@echo ------------------ Building pkg-config file
	@echo "# Package Information for pkg-config"                        >  $(PKG_CONFIG_FILE)
	@echo "# Author: $(AUTHOR)"                                         >> $(PKG_CONFIG_FILE)
	@echo "# Created: `date`"                                           >> $(PKG_CONFIG_FILE)
	@echo "# Licence: $(LICENSE)"                                       >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo prefix=$(PREFIX)                                              >> $(PKG_CONFIG_FILE)
	@echo exec_prefix=$(PREFIX)                                         >> $(PKG_CONFIG_FILE)
	@echo libdir=$(LIB_DIR)                                             >> $(PKG_CONFIG_FILE)
	@echo includedir=$(INCLUDE_DIR)                                     >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo Name: "$(PROJECT_NAME)"                                       >> $(PKG_CONFIG_FILE)
	@echo Description: "$(DESCRIPTION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Version: "$(VERSION)"                                         >> $(PKG_CONFIG_FILE)
	@echo Libs: -L$(LIB_DIR) $(LINKERFLAG)-l$(PROJECT_NAME)-$(COMPILER) >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)                                      >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)


# For build lib need create object files and after run make-lib
$(LIBNAME): $(OBJECTS)
	@echo ------------------ Building static library
	$(make-lib)

# For build shared lib need create shared object files
$(SONAME): $(PICOBJECTS)
	@echo ------------------ Building shared library
	$(MKDIR) $(DLIB_PATH)
	$(DC) -shared $(OUTPUT)$(DLIB_PATH)$(PATH_SEP)$@.$(VERSION) $^
	#~ $(CC) -shared -Wl,-soname,$@.$(VERSION) -o $(DLIB_PATH)$(PATH_SEP)$@.$(VERSION) $^

# create object files
$(BUILD_PATH)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# create shared object files
$(BUILD_PATH)$(PATH_SEP)%.pic.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(FPIC) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)$(PATH_SEP)%.di : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $< $(HF)$@

# Generate Documentation
$(DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ)  $< $(DF)$@

# Generate ddoc Documentation
$(DDOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@

############# CLEAN #############
clean: clean-objects clean-static-lib clean-doc clean-header clean-pkgfile
	@echo ------------------ Cleaning $^ done

clean-shared: clean-shared-objects clean-shared-lib
	@echo ------------------ Cleaning $^ done

clean-objects:
	$(RM) $(OBJECTS)
	@echo ------------------ Cleaning objects done

clean-shared-objects:
	$(RM) $(PICOBJECTS)
	@echo ------------------ Cleaning shared-object done

clean-static-lib:
	$(RM) $(DLIB_PATH)$(PATH_SEP)$(LIBNAME)
	@echo ------------------ Cleaning static-lib done

clean-shared-lib:
	$(RM)  $(DLIB_PATH)$(PATH_SEP)$(SONAME).$(VERSION)
	@echo ------------------ Cleaning shared-lib done

clean-header:
	$(RM) $(HEADERS)
	@echo ------------------ Cleaning header done

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)
	@echo ------------------ Cleaning doc done

clean-ddoc:
	$(RM) $(DDOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOC_PATH)
	@echo ------------------ Cleaning ddoc done

clean-geany-tag:
	$(RM) geany_config $(PROJECT_NAME).d.tags
	@echo ------------------ Cleaning geany tag done

clean-pkgfile:
	$(RM) $(PKG_CONFIG_FILE)
	@echo ------------------ Cleaning pkgfile done

############# INSTALL #############

install: install-static-lib install-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install: install-shared-lib install-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-static-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(LIBNAME) $(DESTDIR)$(LIB_DIR)
	@echo ------------------ Installing static-lib done

install-shared-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(SONAME) $(DESTDIR)$(LIB_DIR)
	ln -s $(DESTDIR)$(LIB_DIR)$(SONAME).$(SO_VERSION)   $(DESTDIR)$(LIB_DIR)$(PATH_SEP)$(SONAME)
	@echo ------------------ Installing shared-lib done

install-header:
	$(MKDIR) $(INCLUDE_DIR)
	$(CP) $(IMPORT_PATH)$(PATH_SEP)* $(DESTDIR)$(INCLUDE_DIR)
	@echo ------------------ Installing header done

install-doc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)
	$(CP) $(DOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)normal_doc$(PATH_SEP)
	@echo ------------------ Installing doc done

install-ddoc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	$(CP) $(DDOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)cute_doc$(PATH_SEP)
	@echo ------------------ Installing ddoc done

install-geany-tag:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	$(CP) $(PROJECT_NAME).d.tags $(DESTDIR)$(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	@echo ------------------ Installing geany tag done

install-pkgfile:
	$(MKDIR) $(PKGCONFIG_DIR)
	$(CP) $(PKG_CONFIG_FILE) $(DESTDIR)$(PKGCONFIG_DIR)
	@echo ------------------ Installing pkgfile done
