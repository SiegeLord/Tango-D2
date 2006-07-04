# Relative path to the tango include dir
# This is where the tango tree is located
TANGO_DIR = ..

# The build tool executable from dsource.org/projects/build
BUILDTOOL = build302
BUILDOPTS = -noautoimport -op -clean -I$(TANGO_DIR)

PHOBOS_DIR = $(TANGO_DIR)/phobos
ZLIB_DIR = $(PHOBOS_DIR)/etc/c/zlib
ZLIB = $(ZLIB_DIR)/zlib.a

.PHONY: all

# Standart target
all : 


SIMPLE_EXAMPLES =       \
	./hello         \
	./filecat       \
	./stdout        \
	./servletserver \
	./chainsaw      \
	./composite     \
	./httpserver    \
	./servlets      \
	./randomio      \
	./localtime     \
	./filecopy      \
	./filebubbler   \
	./localetime    \
	./lineio        \
	./httpget       \
	./socketserver  \
	./token         \
	./filescan      \
	./homepage      \
	./logging       \
	./mmap          \
	./unifile

PHOBOS_EXAMPLES =       	\
	./test_phobos		\
	./phobos/htmlget 	\
	./phobos/hello 		\
	./phobos/listener 	\
	./phobos/dhry 		\
	./phobos/pi 		\
	./phobos/wc 		\
	./phobos/d2html 	\
	./phobos/sieve 		\
	./phobos/wc2 

# At the moment there are problems on linux with the 
# "Missing ModuleInfo" issue.
# Adding these modules to the modules to link
# is a workaround. This can be removed if this 
# problem is solved.
BUG_MODS = 				\
	tango/stdc/posix/pthread.d 	\
	tango/stdc/posix/semaphore.d 	\
	tango/stdc/posix/unistd.d 	\
	tango/stdc/math.d 		\
	tango/stdc/posix/sys/mman.d  	\
	tango/stdc/signal.d
	
$(SIMPLE_EXAMPLES) : % : %.d
	$(BUILDTOOL) $< $(BUG_MODS) $(BUILDOPTS) -T$@

$(PHOBOS_EXAMPLES) : % : %.d $(ZLIB)
	$(BUILDTOOL) $< $(BUG_MODS) $(BUILDOPTS) -T$@ -Mphobos $(ZLIB) -L-ldl

$(ZLIB) :
	$(MAKE) -C $(ZLIB_DIR) -f linux.mak

all : $(SIMPLE_EXAMPLES) $(PHOBOS_EXAMPLES)
	
clean :
	rm $(SIMPLE_EXAMPLES) $(PHOBOS_EXAMPLES)
	



