ROOT_SRC_DIR       = ../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = ldc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: ldc-build
install: ldc-install
clean: ldc-clean
mrproper: ldc-mrproper
.PHONY: clean mrproper ldc-mrproper ldc-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
ldc-build: $(OBJ)
ldc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
ldc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
ldc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
ldc-phony: .PHONY
