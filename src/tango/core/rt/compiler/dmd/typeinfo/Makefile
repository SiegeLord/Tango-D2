ROOT_SRC_DIR       = ../../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = typeinfo/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/typeinfo/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: typeinfo-build
install: typeinfo-install
clean: typeinfo-clean
mrproper: typeinfo-mrproper
.PHONY: clean mrproper typeinfo-mrproper typeinfo-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
typeinfo-build: $(OBJ)
typeinfo-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
typeinfo-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
typeinfo-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
typeinfo-phony: .PHONY
