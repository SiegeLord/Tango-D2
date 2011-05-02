ROOT_SRC_DIR       = ../../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = posix/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/posix/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: posix-build
install: posix-install
clean: posix-clean
mrproper: posix-mrproper
.PHONY: clean mrproper posix-mrproper posix-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
posix-build: $(OBJ)
posix-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
posix-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
posix-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
posix-phony: .PHONY
