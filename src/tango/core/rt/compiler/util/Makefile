ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = util/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/util/
SRC                = $(wiutilard *.d)
OBJ                = $(SRC:.d=.o)
build: util-build
install: util-install
clean: util-clean
mrproper: util-mrproper
.PHONY: clean mrproper util-mrproper util-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
util-build: $(OBJ)
util-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
util-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
util-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
util-phony: .PHONY
