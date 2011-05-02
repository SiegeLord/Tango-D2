ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = basic/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/basic/
SRC                = $(wibasicard *.d)
OBJ                = $(SRC:.d=.o)
build: basic-build
install: basic-install
clean: basic-clean
mrproper: basic-mrproper
.PHONY: clean mrproper basic-mrproper basic-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
basic-build: $(OBJ)
basic-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
basic-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
basic-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
basic-phony: .PHONY
