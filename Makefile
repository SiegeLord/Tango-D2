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

distclean:
	rm -rf $(OBJDIR)

ifeq ($(shell if [ -e "$(OBJDIR)/intermediate.rule" ]; then echo 1; fi;),1)
include $(OBJDIR)/intermediate.rule
endif
ifneq ($(strip $(wildcard *.dep)),)
include $(wildcard *.dep)
endif
