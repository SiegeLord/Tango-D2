# Makefile that builds the tango runtime
#
# * Targets
# all:       (the default) builds lib
# lib:       should build the optimized tango library
# newFiles:  updates the module list when new d diles are added
#            either this or clean-all or distclean have to be called to compile the new files
# clean:     cleans the buildobjects
# clean-all: removes the current object directory
# distclean: removes all object directories 
#
# * Compiler
# By default make tries to guess the compiler to use. If you have several compilers you can 
# select the compiler to use by setting the DC environment variable or by setting DC in the
# make invocation
#
# * Version
# By default the optimized version will be built, you can build other versions by passing
# VERSION=dbg or VERSION=tst (for example) to the make invocation
# 
# * Architecture
# The architecture is identified by what is returned by tango/build/tools/archName.sh
# (which is os-machine) togheter with the compiler and version. This forms a quadruplet
# os-machine-compiler-version that is called IDENT.
# It is used to generate the object directory, and to get the architecture dependent flags
# and rules.
# This is done by reading the file tango/build/arch/$(IDENT).mak
# It is possible to override IDENT by passing IDENT=mySpecialIdent to the make invocation.
# In this case the version flag is disregarded. 
# For problems with the flags (or if you want to define a new special build setting)
# normally you should edit the tango/build/arch/$(IDENT).mak file.
#
# * Other important variables
# DFLAGS_ADD: adds the given D flags
# CFLAGS_ADD: adds the given C flags
# DFLAGS: as environment variable is not changed
# CFLAGS: adds the given C flags
#
# tango & apache 2.0 license, © 2009 Fawzi Mohamed


TANGO_HOME=$(shell pwd)/../..
TOOLDIR=$(TANGO_HOME)/build/tools
VERSION=opt
DC=$(shell $(TOOLDIR)/guessCompiler.sh --path)
DC_SHORT=$(shell $(TOOLDIR)/guessCompiler.sh $(DC))
IDENT=$(shell $(TOOLDIR)/archName.sh)-$(DC_SHORT)-$(VERSION)

SRCDIR=$(TANGO_HOME)/runtime
OBJDIRBASE=$(TANGO_HOME)/build
OBJDIR=$(OBJDIRBASE)/runtime/objs-$(IDENT)
ARCHDIR=$(TANGO_HOME)/build/arch
EXCLUDEPAT_ALL=$(EXCLUDEPAT_OS) 
ARCHFILE=$(ARCHDIR)/$(IDENT).mak
MAKEFILE=$(TANGO_HOME)/build/runtime/Makefile
WHAT=_lib
GC=basic
PLACES=common compiler/shared gc/$(GC) compiler/$(DC_SHORT)
DFLAGS_ADD=-I$(TANGO_HOME)/runtime $(PLACES:%=-I$(TANGO_HOME)/runtime/%) -I$(TANGO_HOME)/user
LIB=$(LIB_PREFIX)tango-base.$(LIB_EXT)
INSTALL_LIB=$(TANGO_HOME)/build/libs/$(LIB_PREFIX)tango-base-$(shell $(TOOLDIR)/getCompVers.sh $(IDENT)).$(LIB_EXT)

all: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" WHAT=_lib build
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" WHAT=_install build

include $(ARCHFILE)
include $(PLACES:%=$(TANGO_HOME)/build/runtime/%/OBJDEFS.inc)
ifeq ($(shell if [ -e "$(OBJDIR)/MODULES.inc" ]; then echo 1; fi;),1)
include $(OBJDIR)/MODULES.inc
endif

vpath %d $(TANGO_HOME)/runtime
vpath %di $(TANGO_HOME)/runtime
vpath %S $(TANGO_HOME)/runtime
vpath %c $(TANGO_HOME)/runtime
vpath %asm $(TANGO_HOME)/runtime
vpath %d $(PLACES:%=$(TANGO_HOME)/runtime/%)
vpath %di $(PLACES:%=$(TANGO_HOME)/runtime/%)
vpath %S $(PLACES:%=$(TANGO_HOME)/runtime/%)
vpath %c $(PLACES:%=$(TANGO_HOME)/runtime/%)
vpath %asm $(PLACES:%=$(TANGO_HOME)/runtime/%)

EXCLUDE_DEP_ALL=$(EXCLUDE_DEP_COMP)

MODULES=$(COMMON_MODULES) $(GC_MODULES) $(COMPILER_MODULES) $(ARCH_MODULES) $(OS_MODULES)
OTHER_OBJS=$(COMMON_OO) $(GC_OO) $(COMPILER_OO) $(OS_OO) $(ARCH_OO)
OBJS=$(MODULES:%=%.$(OBJ_EXT)) $(OTHER_OBJS)
INSTALL_DI=$(COMMON_DI) $(GC_DI) $(COMPILER_DI) $(OS_DI) $(ARCH_DI)

.PHONY: _genDeps newFiles build clean distclean allVersions install

install: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" WHAT=_install build

allVersions: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" VERSION=opt DC="$(DC)" WHAT=_lib build
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" VERSION=dbg DC="$(DC)" WHAT=_lib build
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" VERSION=dbg DC="$(DC)" WHAT=_install build

build: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	@echo "XXX using the architecture file $(ARCHFILE)"
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" _genDeps
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" $(WHAT)

_install:
	$(TOOLDIR)/mkDi.sh --tango-dir "$(TANGO_HOME)" $(INSTALL_DI:%.di=%)

_genDeps: $(MODULES:%=%.dep)

_lib:$(INSTALL_LIB)

.INTERMEDIATE: $(LIB)

$(LIB):  $(OBJS)
	rm -f $@
	$(mkLib) $(out_lib_name)$@ $(OBJS)
ifneq ($(ranlib),)
	$(ranlib) $@
endif

$(INSTALL_LIB): $(LIB)
	mkdir -p $(TANGO_HOME)/build/libs
	cp $(OBJDIR)/$(LIB) $(INSTALL_LIB)

$(OBJDIR)/MODULES.inc:
	@mkdir -p $(OBJDIR)
	touch $(OBJDIR)/MODULES.inc
#	$(TOOLDIR)/mkMods.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/MODULES.inc

$(OBJDIR)/intermediate.rule:
	@mkdir -p $(OBJDIR)
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh common $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh gc/basic $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh compiler/$(DC_SHORT) $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh compiler/shared $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule

newFiles:
	@mkdir -p $(OBJDIR)
	@echo regenerating MODULES.inc and intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh common $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh gc/basic $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh compiler/$(DC_SHORT) $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule
	cd $(TANGO_HOME)/runtime && $(TOOLDIR)/mkIntermediate.sh compiler/shared $(EXCLUDEPAT_ALL) >> $(OBJDIR)/intermediate.rule

clean:
	rm -f $(OBJDIR)/*.$(OBJ_EXT)
	rm -f $(OBJDIR)/*.dep

clean-all:
	rm -rf $(OBJDIR)

prebuildclean:
	rm -rf $(OBJDIRBASE)/runtime/objs-*
	rm -f $(TANGO_HOME)/build/libs/$(LIB_PREFIX)tango-base-*
	find $(TANGO_HOME)/user/tango -name '*.di' | xargs rm -f
	rm -rf $(TANGO_HOME)/user/rt

distclean:
	rm -rf $(OBJDIRBASE)/runtime/objs-*
	rm -f $(TANGO_HOME)/build/libs/$(LIB_PREFIX)tango-base-*
	find $(TANGO_HOME)/user -name '*.di' -a -not -name object.di | xargs rm -f

ifeq ($(shell if [ -e "$(OBJDIR)/intermediate.rule" ]; then echo 1; fi;),1)
include $(OBJDIR)/intermediate.rule
endif
ifneq ($(strip $(wildcard *.dep)),)
include $(wildcard *.dep)
endif
