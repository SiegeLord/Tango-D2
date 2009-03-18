# GDC -- D front-end for GCC
# Copyright (C) 2004 David Friedman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# AUTOMAKE_OPTIONS = 1.9.6 foreign no-dependencies

OUR_CFLAGS=@DEFS@ -I.
D_EXTRA_DFLAGS=-nostdinc -pipe -I../../.. -I../shared -fversion=Posix
ALL_DFLAGS = $(DFLAGS) $(D_MEM_FLAGS) $(D_EXTRA_DFLAGS) $(MULTIFLAGS)

host_alias=.

toolexecdir = $(phobos_toolexecdir)
toolexeclibdir = $(phobos_toolexeclibdir)

config_d_src=$(host_alias)/gcc/config.d
configunix_d_src=$(host_alias)/gcc/configunix.d

# This is a hook to get Automake to build libgphobos.a
BUILT_SOURCES = minimal.c
noinst_PROGRAMS = minimal
minimal_SOURCES = minimal.c
minimal_DEPENDENCIES = libgphobos.a
minimal.c:
	echo "int main() { return 0; }" > $@

all-local: libgphobos.a

SUFFIXES = .d

%.o : %.d $(D_PREREQ_SRCS)
	$(GDC) -o $@ $(ALL_DFLAGS)  \
	-c $<

# %.o : %.c
# Use .c.o to override Automake
.c.o:
	$(CC) -o $@ $(OUR_CFLAGS) $(CFLAGS) -c $<

%.t.o : %.d $(D_PREREQ_SRCS)
	$(GDC) -o $@ $(ALL_DFLAGS) -fno-release -funittest -c $<

%.t.o : %.o
	cp $< $@

unittest: unittest.o libgphobos_t.a libgphobos.a
	$(GDC) -o $@ $(CFLAGS) unittest.o -L./ -lgphobos_t $(LIBS)

TI=ti_AC.o ti_Ag.o ti_Aint.o ti_Along.o ti_Ashort.o \
	ti_C.o \
	ti_byte.o ti_cdouble.o ti_cfloat.o ti_char.o ti_creal.o \
	ti_dchar.o ti_delegate.o ti_double.o ti_float.o ti_idouble.o ti_ifloat.o \
	ti_int.o  ti_ireal.o ti_long.o ti_ptr.o ti_real.o ti_short.o ti_ubyte.o \
	ti_uint.o ti_ulong.o ti_ushort.o ti_wchar.o \
	ti_Afloat.o ti_Adouble.o ti_Areal.o \
	ti_Acfloat.o ti_Acdouble.o ti_Acreal.o \
	ti_void.o

OBJ_BASE= \
    aaA.o \
    aApply.o \
    aApplyR.o \
    adi.o \
    arraycast.o \
    arraycat.o \
    cast.o \
    cmain.o \
    critical.o \
    dgccmain2.o \
    genobj.o \
    invariant.o \
    lifetime.o \
    memory.o \
    memset.o \
    monitor.o \
    obj.o \
    qsortg.o \
    rundmain.o \
    switch.o \
    rt/cImports.o

OBJ_UTIL= \
    ../shared/rt/util/console.o \
    ../shared/rt/util/ctype.o \
    ../shared/rt/util/string.o \
    ../shared/rt/util/utf.o \
    ../shared/rt/util/hash.o

OBJ_EXT = \
    std/intrinsic.o

OBJ_MEM = @D_MEM_MODULES@

MAIN_OBJS=$(subst ti_,../shared/rt/typeinfo/ti_,$(TI))

# This should not be linked into a shared library.
CMAIN_OBJS=

ZLIB_OBJS=

GC_OBJS=

# Removed threadsem for Tango
GCC_OBJS = gcc/config.o gcc/unwind.o gcc/deh.o gcc/cbridge_time.o

# std.c.linux.linux, std.loader, gcc.cbridge*
WINDOWS_OBJS=
# D_EXTRA_OBJS=@D_EXTRA_OBJS@

# currently just add compatibility for a bug
D_EXTRA_OBJS+=gcc/support.o

CONFIG_D_FRAGMENTS = config/config-head frag-ac frag-gen frag-math config/config-mid config/config-tail
CONFIG_UNIX_FRAGMENTS = config/unix-head frag-unix config/unix-mid

gen_config1: config/gen_config1.o
	$(CC) $(CFLAGS) -o $@ $^

$(config_d_src): $(CONFIG_D_FRAGMENTS) stamp-tgtdir
	cat $^ > $@

gcc/config.o: $(config_d_src)
	$(GDC) -o $@ $(ALL_DFLAGS) -c $<
gcc/config.t.o: gcc/config.o
	cp gcc/config.o gcc/config.t.o


gen_math: config/gen_math.o
	$(CC) $(CFLAGS) -o $@ $^

config/gen_unix.o: config/gen_unix.c config/makestruct.h

gen_unix: config/gen_unix.o
	$(CC) $(CFLAGS) -o $@ $^


# Plain 'make' would use: ifdef D_GENERATE_FRAGMENTS
if D_GENERATE_FRAGMENTS
frag-gen: gen_config1
	./gen_config1 > $@ || rm -f $@
frag-unix: gen_unix
	./gen_unix > $@
frag-math: gen_math
	./gen_math > $@ || rm -f $@
else
frag-gen: $(D_FRAGMENT_SRCDIR)/$@
	cp $(D_FRAGMENT_SRCDIR)/$@ $@
frag-unix: $(D_FRAGMENT_SRCDIR)/$@
	cp $(D_FRAGMENT_SRCDIR)/$@ $@
frag-math: $(D_FRAGMENT_SRCDIR)/$@
	cp $(D_FRAGMENT_SRCDIR)/$@ $@
endif

$(configunix_d_src): $(CONFIG_UNIX_FRAGMENTS) stamp-tgtdir
	cat $^ > $@

gcc/configunix.o: $(configunix_d_src) $(config_d_src)
	$(GDC) -o $@ $(ALL_DFLAGS) -c $<
gcc/configunix.t.o: gcc/configunix.o
	cp gcc/configunix.o gcc/configunix.t.o

gcc/cbridge_math.o: gcc/cbridge_math.c
	$(CC) -o $@ $(OUR_CFLAGS) $(CFLAGS) -fno-strict-aliasing -c $<

# GCC_OBJS (gcc/config.o) first so I don't have to write more deps
ALL_PHOBOS_OBJS = $(OBJ_BASE) $(OBJ_UTIL) $(OBJ_EXT) $(OBJ_MEM) $(D_EXTRA_OBJS) $(GCC_OBJS) $(MAIN_OBJS) $(ZLIB_OBJS) $(GC_OBJS) $(WEAK_OBJS)

libgphobos.a : $(ALL_PHOBOS_OBJS) $(CMAIN_OBJS)
	$(AR) -r $@ $(ALL_PHOBOS_OBJS) $(CMAIN_OBJS)
	$(RANLIB) $@

libgphobos_t.a : $(ALL_PHOBOS_OBJS:.o=.t.o) $(CMAIN_OBJS)
	$(AR) -r $@ $(ALL_PHOBOS_OBJS:.o=.t.o) $(CMAIN_OBJS)
	$(RANLIB) $@

# This has to be an empty file because it is included in the prerequisites of rules
# that use "cat $^" to generate their targets.
# Otherwise, need to specify $srcdir for known source files in CONFIG_xxx_FRAGMENTS..
stamp-tgtdir:
	mkdir -p $(host_alias)/gcc
	touch $@

check-local: unittest testgc
	./unittest
	./testgc

install-exec-local: $(D_PREREQ_SRCS) libgphobos.a
	$(mkinstalldirs) $(DESTDIR)$(toolexeclibdir)
	$(INSTALL) libgphobos.a $(DESTDIR)$(toolexeclibdir)
	$(RANLIB) $(DESTDIR)$(toolexeclibdir)/libgphobos.a

install-data-local: $(D_PREREQ_SRCS) libgphobos.a
	for i in gcc; do \
		$(mkinstalldirs) $(DESTDIR)$(gdc_include_dir)/$$i; \
		for f in $(srcdir)/$$i/*.[hd]; do $(INSTALL_HEADER) $$f $(DESTDIR)$(gdc_include_dir)/$$i; done; \
		for f in $(srcdir)/$$i/*.di; do $(INSTALL_HEADER) $$f $(DESTDIR)$(gdc_include_dir)/$$i; done; \
	done
	$(mkinstalldirs) $(DESTDIR)$(gdc_include_dir)/$(host_alias)/$(MULTISUBDIR)/gcc
	$(INSTALL_HEADER) $(config_d_src) $(DESTDIR)$(gdc_include_dir)/$(host_alias)/$(MULTISUBDIR)/gcc
	if test -f $(configunix_d_src); then $(INSTALL_HEADER) $(host_alias)/gcc/configunix.d $(DESTDIR)$(gdc_include_dir)/$(host_alias)/$(MULTISUBDIR)/gcc; fi
	$(INSTALL) phobos-ver-syms $(DESTDIR)$(gdc_include_dir)/$(host_alias)/$(MULTISUBDIR)

clean-local:
	rm -f $(ALL_PHOBOS_OBJS) $(CMAIN_OBJS)
	rm -f $(ALL_PHOBOS_OBJS:.o=.t.o)
	rm -f unittest.o
	rm -f unittest$(EXEEXT) testgc$(EXEEXT)ava
	rm -f config/gen_config1.o config/gen_unix.o config/gen_math.o
	rm -f gen_config1$(EXEEXT) gen_unix$(EXEEXT) gen_math$(EXEEXT)
	rm -f frag-gen frag-math frag-unix
	rm -f $(config_d_src)
	rm -f libgphobos.a
	rm -f libgphobos_t.a


# Work around what appears to be a GNU make bug handling MAKEFLAGS
# values defined in terms of make variables, as is the case for CC and
# friends when we are called from the top level Makefile.
AM_MAKEFLAGS = \
	"AR_FLAGS=$(AR_FLAGS)" \
	"CC_FOR_BUILD=$(CC_FOR_BUILD)" \
	"CC_FOR_TARGET=$(CC_FOR_TARGET)" \
	"CFLAGS=$(CFLAGS)" \
	"CXXFLAGS=$(CXXFLAGS)" \
	"CFLAGS_FOR_BUILD=$(CFLAGS_FOR_BUILD)" \
	"CFLAGS_FOR_TARGET=$(CFLAGS_FOR_TARGET)" \
	"INSTALL=$(INSTALL)" \
	"INSTALL_DATA=$(INSTALL_DATA)" \
	"INSTALL_PROGRAM=$(INSTALL_PROGRAM)" \
	"INSTALL_SCRIPT=$(INSTALL_SCRIPT)" \
	"LDFLAGS=$(LDFLAGS)" \
	"LIBCFLAGS=$(LIBCFLAGS)" \
	"LIBCFLAGS_FOR_TARGET=$(LIBCFLAGS_FOR_TARGET)" \
	"MAKE=$(MAKE)" \
	"MAKEINFO=$(MAKEINFO) $(MAKEINFOFLAGS)" \
	"PICFLAG=$(PICFLAG)" \
	"PICFLAG_FOR_TARGET=$(PICFLAG_FOR_TARGET)" \
	"SHELL=$(SHELL)" \
	"RUNTESTFLAGS=$(RUNTESTFLAGS)" \
	"exec_prefix=$(exec_prefix)" \
	"infodir=$(infodir)" \
	"libdir=$(libdir)" \
	"includedir=$(includedir)" \
	"prefix=$(prefix)" \
	"tooldir=$(tooldir)" \
	"gdc_include_dir=$(gdc_include_dir)" \
	"AR=$(AR)" \
	"AS=$(AS)" \
	"LD=$(LD)" \
	"RANLIB=$(RANLIB)" \
	"NM=$(NM)" \
	"NM_FOR_BUILD=$(NM_FOR_BUILD)" \
	"NM_FOR_TARGET=$(NM_FOR_TARGET)" \
	"DESTDIR=$(DESTDIR)" \
	"WERROR=$(WERROR)"

# Subdir rules rely on $(FLAGS_TO_PASS)
FLAGS_TO_PASS = $(AM_MAKEFLAGS)
