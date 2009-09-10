# Makefile that builds the tango-user library
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

SRCDIR=$(TANGO_HOME)/user
OBJDIRBASE=$(TANGO_HOME)/build
OBJDIR=$(OBJDIRBASE)/user/objs-$(IDENT)
ARCHDIR=$(TANGO_HOME)/build/arch
EXCLUDEPAT_ALL=$(EXCLUDEPAT_OS) $(EXCLUDEPAT_COMP)
ARCHFILE=$(ARCHDIR)/$(IDENT).mak
MAKEFILE=$(TANGO_HOME)/build/user/Makefile
DFLAGS_ADD=-I$(TANGO_HOME)/user
WHAT=_lib

LIB=$(LIB_PREFIX)tango-user.$(LIB_EXT)
INSTALL_LIB=$(TANGO_HOME)/build/libs/$(LIB_PREFIX)tango-user-$(shell $(TOOLDIR)/getCompVers.sh $(IDENT)).$(LIB_EXT)

all: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" WHAT=_lib build

include $(ARCHFILE)
ifeq ($(shell if [ -e "$(OBJDIR)/MODULES.inc" ]; then echo 1; fi;),1)
include $(OBJDIR)/MODULES.inc
endif

vpath %d $(SRCDIR)
vpath %di $(SRCDIR)

EXCLUDE_DEP_ALL=$(EXCLUDE_DEP_COMP)  $(EXCLUDE_DEP_OS)

OBJS=$(MODULES:%=%.$(OBJ_EXT))

.PHONY: _genDeps newFiles build clean distclean allVersions

allVersions:	$(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" VERSION=opt DC="$(DC)" all
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" VERSION=dbg DC="$(DC)" all

build: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	@echo "XXX using the architecture file $(ARCHFILE)"
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" _genDeps
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" $(WHAT)

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
	$(TOOLDIR)/mkMods.sh $(SRCDIR)/tango $(EXCLUDEPAT_ALL) > $(OBJDIR)/MODULES.inc

$(OBJDIR)/intermediate.rule:
	@mkdir -p $(OBJDIR)
	$(TOOLDIR)/mkIntermediate.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule

newFiles:
	@mkdir -p $(OBJDIR)
	@echo regenerating MODULES.inc and intermediate.rule
	$(TOOLDIR)/mkMods.sh $(SRCDIR)/tango $(EXCLUDEPAT_ALL) > $(OBJDIR)/MODULES.inc
	$(TOOLDIR)/mkIntermediate.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule

clean:
	rm -f $(OBJDIR)/*.$(OBJ_EXT)
	rm -f $(OBJDIR)/*.dep

clean-all:
	rm -rf $(OBJDIR)

distclean:
	rm -rf $(OBJDIRBASE)/user/objs-*
	rm -f $(TANGO_HOME)/build/libs/$(LIB_PREFIX)tango-user-*$(DC_SHORT)*

ifeq ($(shell if [ -e "$(OBJDIR)/intermediate.rule" ]; then echo 1; fi;),1)
include $(OBJDIR)/intermediate.rule
endif
ifneq ($(strip $(wildcard *.dep)),)
include $(wildcard *.dep)
endif
