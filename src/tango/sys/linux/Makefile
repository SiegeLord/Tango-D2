ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = linux/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: linux-build
install: linux-install
clean: linux-clean
mrproper: linux-mrproper
.PHONY: clean mrproper linux-mrproper linux-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
linux-build: $(OBJ)
linux-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
linux-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
linux-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
linux-phony: .PHONY
