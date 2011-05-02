ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = cdgc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/cdgc/
SRC                = $(wicdgcard *.d)
OBJ                = $(SRC:.d=.o)
build: cdgc-build
install: cdgc-install
clean: cdgc-clean
mrproper: cdgc-mrproper
.PHONY: clean mrproper cdgc-mrproper cdgc-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
cdgc-build: $(OBJ)
cdgc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
cdgc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
cdgc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
cdgc-phony: .PHONY
