ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = util/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: util-build c-build
install: util-install c-install
clean: util-clean c-clean
mrproper: util-mrproper c-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
util-build: $(OBJ)
c-build:
	@(echo -e "\033[31mBuilding c\033[0;0m")
	$(MAKE) -C c build
util-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
c-install:
	@(echo -e "\033[31mInstalling c\033[0;0m")
	$(MAKE) -C c install
util-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
c-clean:
	@(echo -e "\033[31mCleaning object from c\033[0;0m")
	$(MAKE) -C c clean
util-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
c-mrproper:
	@(echo -e "\033[31mRuning mrproper on c\033[0;0m")
	$(MAKE) -C c mrproper
util-phony: .PHONY
