ROOT_SRC_DIR       = ../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = gc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/gc/
SRC                = $(wigcard *.d)
OBJ                = $(SRC:.d=.o)
build: gc-build
install: gc-install
clean: gc-clean
mrproper: gc-mrproper
.PHONY: clean mrproper gc-mrproper gc-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
gc-build: $(OBJ)
gc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
gc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
gc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
gc-phony: .PHONY
