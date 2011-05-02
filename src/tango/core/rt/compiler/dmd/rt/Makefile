ROOT_SRC_DIR       = ../../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = rt/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/rt/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: rt-build
install: rt-install
clean: rt-clean
mrproper: rt-mrproper
.PHONY: clean mrproper rt-mrproper rt-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
rt-build: $(OBJ)
rt-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
rt-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
rt-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
rt-phony: .PHONY
