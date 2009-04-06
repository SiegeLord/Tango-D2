.SUFFIXES: .s .S .c .cpp .d .html .o .ll .bc
CP=cp -f
RM=rm -f
MD=mkdir -p

ifeq ($(SHARED),yes)
C_SHARED_FLAGS=-fPIC
D_SHARED_FLAGS=-relocation-model=pic
T_SHARED_FLAGS=-fPIC
else
C_SHARED_FLAGS=
D_SHARED_FLAGS=
T_SHARED_FLAGS=
endif

CFLAGS_RELEASE=-O2 
CFLAGS_DEBUG=-g -w 
DFLAGS_RELEASE=-release -O3 -inline -output-bc -w 
DFLAGS_DEBUG=-g -w -output-bc
TFLAGS_RELEASE=-O3 -inline -w
TFLAGS_DEBUG=-g -w

ifeq ($(VERSION),debug)
CFLAGS=$(CFLAGS_DEBUG) $(LOCAL_CFLAGS) $(C_SHARED_FLAGS) $(ADD_CFLAGS)
DFLAGS=$(DFLAGS_DEBUG) $(LOCAL_DFLAGS) $(D_SHARED_FLAGS) $(ADD_DFLAGS)
TFLAGS=$(TFLAGS_DEBUG) $(LOCAL_TFLAGS) $(T_SHARED_FLAGS) $(ADD_DFLAGS)
else
CFLAGS=$(CFLAGS_RELEASE) $(LOCAL_CFLAGS) $(C_SHARED_FLAGS) $(ADD_CFLAGS)
DFLAGS=$(DFLAGS_RELEASE) $(LOCAL_DFLAGS) $(D_SHARED_FLAGS) $(ADD_DFLAGS)
TFLAGS=$(TFLAGS_RELEASE) $(LOCAL_TFLAGS) $(T_SHARED_FLAGS) $(ADD_DFLAGS)
endif

DOCFLAGS=-version=DDoc

CC=gcc
LC=llvm-ar rsv
LLINK=llvm-link
LCC=llc
CLC=ar rsv
DC=ldc
LLC=llvm-as

.s.o:
	$(CC) -c $(CFLAGS) $< -o$@

.S.o:
	$(CC) -c $(CFLAGS) $< -o$@

.c.o:
	$(CC) -c $(CFLAGS) $< -o$@

.cpp.o:
	g++ -c $(CFLAGS) $< -o$@

.bc:.o

.d.o:
	$(DC) -c $(DFLAGS) $< -of$@

.ll.bc:
	$(LLC) -f -o=$@ $<

.d.html:
	$(DC) -c -o- $(DOCFLAGS) -Df$*.html dmd.ddoc $<

######################################################
unittest :
	make -f$(MAKEFILE) clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -f$(MAKEFILE) libs DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)" \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS) -unittest -d-debug=UnitTest" \
		SHARED="$(SHARED)"
lib-release :
	make -f$(MAKEFILE) clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -f$(MAKEFILE) DC="$(DC)" LIB_BUILD="" VERSION=release libs \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"
lib-debug :
	make -f$(MAKEFILE) clean DC="$(DC)" LIB_BUILD="" VERSION="$(VERSION)"
	make -f$(MAKEFILE) DC="$(DC)" LIB_BUILD="-d" VERSION=debug libs \
		ADD_CFLAGS="$(ADD_CFLAGS)" ADD_DFLAGS="$(ADD_DFLAGS)" SYSTEM_VERSION="$(SYSTEM_VERSION)"

