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
# The architecture is identified by what is returned by tango/lib/build/tools/archName.sh
# (which is os-machine) togheter with the compiler and version. This forms a quadruplet
# os-machine-compiler-version that is called IDENT.
# It is used to generate the object directory, and to get the architecture dependent flags
# and rules.
# This is done by reading the file tango/lib/build/arch/$(IDENT).mak
# It is possible to override IDENT by passing IDENT=mySpecialIdent to the make invocation.
# In this case the version flag is disregarded. 
# For problems with the flags (or if you want to define a new special build setting)
# normally you should edit the tango/lib/build/arch/$(IDENT).mak file.
#
# tango & apache 2.0 license, © 2009 Fawzi Mohamed


TANGO_HOME=$(PWD)
TOOLDIR=$(TANGO_HOME)/lib/build/tools
VERSION=opt
DC=$(shell $(TOOLDIR)/guessCompiler.sh --path)
DC_SHORT=$(shell $(TOOLDIR)/guessCompiler.sh $(DC))
IDENT=$(shell $(TOOLDIR)/archName.sh)-$(DC_SHORT)-$(VERSION)

SRCDIR=$(TANGO_HOME)/tango
OBJDIR=$(TANGO_HOME)/objs-$(IDENT)
ARCHDIR=$(TANGO_HOME)/lib/build/arch
EXCLUDEPAT_ALL=$(EXCLUDEPAT_OS)
ARCHFILE=$(ARCHDIR)/$(IDENT).mak
MAKEFILE=$(TANGO_HOME)/Makefile

LIB=libtango-user.$(LIB_EXT)
INSTALL_LIB=libtango-user-$(shell $(TOOLDIR)/getCompVers.sh $(IDENT)).$(LIB_EXT)
include $(ARCHFILE)
ifeq ($(shell if [ -e "$(OBJDIR)/MODULES.inc" ]; then echo 1; fi;),1)
include $(OBJDIR)/MODULES.inc
endif

vpath %d $(SRCDIR)
vpath %di $(SRCDIR)

EXCLUDE_DEP_ALL=$(EXCLUDE_DEP_COMP)

OBJS=$(MODULES:%=%.$(OBJ_EXT))

.PHONY: _genDeps newFiles build clean distclean

all: $(OBJDIR)/MODULES.inc $(OBJDIR)/intermediate.rule
	@mkdir -p $(OBJDIR)
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" build

build:
	@echo "XXX using the architecture file $(ARCHFILE)"
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" _genDeps
	$(MAKE) -f $(MAKEFILE) -C $(OBJDIR) TANGO_HOME="$(TANGO_HOME)" IDENT="$(IDENT)" DC="$(DC)" _lib

_genDeps: $(MODULES:%=%.dep)

_lib:$(LIB)

$(LIB):  $(OBJS)
	rm -f $@
	$(mkLib) $@ $(OBJS)
	$(ranlib) $@
	cp $(OBJDIR)/$(LIB) $(TANGO_HOME)/$(INSTALL_LIB)

$(OBJDIR)/MODULES.inc:
	@mkdir -p $(OBJDIR)
	$(TOOLDIR)/mkMods.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/MODULES.inc

$(OBJDIR)/intermediate.rule:
	@mkdir -p $(OBJDIR)
	$(TOOLDIR)/mkIntermediate.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule

newFiles:
	@mkdir -p $(OBJDIR)
	@echo regenerating MODULES.inc and intermediate.rule
	$(TOOLDIR)/mkMods.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/MODULES.inc
	$(TOOLDIR)/mkIntermediate.sh $(SRCDIR) $(EXCLUDEPAT_ALL) > $(OBJDIR)/intermediate.rule

clean:
	rm -f $(OBJDIR)/*.$(OBJ_EXT)
	rm -f $(OBJDIR)/*.dep

clean-all:
	rm -rf $(OBJDIR)

distclean:
	rm -rf $(TANGO_HOME)/objs-*

ifeq ($(shell if [ -e "$(OBJDIR)/intermediate.rule" ]; then echo 1; fi;),1)
include $(OBJDIR)/intermediate.rule
endif
ifneq ($(strip $(wildcard *.dep)),)
include $(wildcard *.dep)
endif
