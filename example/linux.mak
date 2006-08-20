# Makefile to build the examples of tango for Linux
# Designed to work with GNU make
# Targets:
#	make
#		Same as make all
#	make all
#		Build all examples
#
#	make <executable-name>
#		Build a specified example
#   	make clean
#   		remove all build examples
#   
# 

# Relative path to the tango include dir
# This is where the tango tree is located
TANGO_DIR = ..

# The build tool executable from dsource.org/projects/build
BUILDTOOL = build302
BUILDOPTS = -noautoimport -op -clean -I$(TANGO_DIR)

PHOBOS_DIR = $(TANGO_DIR)/phobos
ZLIB_DIR = $(PHOBOS_DIR)/etc/c/zlib
ZLIB = $(ZLIB_DIR)/zlib.a

.PHONY: all clean

# Standart target
all : 


SIMPLE_EXAMPLES =       	\
	./hello         	\
	./filecat       	\
	./stdout        	\
	./servletserver 	\
	./chainsaw      	\
	./composite     	\
	./httpserver    	\
	./servlets      	\
	./randomio      	\
	./localtime     	\
	./filecopy      	\
	./filebubbler   	\
	./localetime    	\
	./lineio        	\
	./httpget       	\
	./socketserver  	\
	./token         	\
	./filescan      	\
	./homepage      	\
	./logging       	\
	./mmap          	\
	./unifile

PHOBOS_EXAMPLES =		\
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

REFERENCE_EXAMPLES =		\
	./reference/chapter4	\
	./reference/chapter11

$(SIMPLE_EXAMPLES) : % : %.d
	@echo "Building : " $@
	@$(BUILDTOOL) $< $(BUILDOPTS) -T$@

$(PHOBOS_EXAMPLES) : % : %.d $(ZLIB)
	@echo "Building : " $@
	@$(BUILDTOOL) $< $(BUILDOPTS) -T$@ -Mphobos $(ZLIB) -L-ldl

$(REFERENCE_EXAMPLES) : % : %.d
	@echo "Building : " $@
	@$(BUILDTOOL) $< $(BUILDOPTS) -T$@

$(ZLIB) :
	@echo "Building *** Phobos ZLIB ***"
	$(MAKE) -C $(ZLIB_DIR) -f linux.mak

all : $(SIMPLE_EXAMPLES) $(PHOBOS_EXAMPLES) $(REFERENCE_EXAMPLES)

clean :
	@echo "Removing all examples"
	rm -f $(SIMPLE_EXAMPLES) $(PHOBOS_EXAMPLES) $(REFERENCE_EXAMPLES)
	rm -f random.bin




