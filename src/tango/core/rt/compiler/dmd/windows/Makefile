ROOT_SRC_DIR       = ../../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = windows/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/windows/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: windows-build
install: windows-install
clean: windows-clean
mrproper: windows-mrproper
.PHONY: clean mrproper windows-mrproper windows-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
windows-build: $(OBJ)
windows-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
windows-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
windows-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
windows-phony: .PHONY
