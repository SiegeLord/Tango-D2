ROOT_SRC_DIR       = ../../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = gcc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/gcc/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: gcc-build
install: gcc-install
clean: gcc-clean
mrproper: gcc-mrproper
.PHONY: clean mrproper gcc-mrproper gcc-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
gcc-build: $(OBJ)
gcc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
gcc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
gcc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
gcc-phony: .PHONY
