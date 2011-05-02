ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = selector/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: selector-build model-build
install: selector-install model-install
clean: selector-clean model-clean
mrproper: selector-mrproper model-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
selector-build: $(OBJ)
model-build:
	@(echo -e "\033[31mBuilding model\033[0;0m")
	$(MAKE) -C model build
selector-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
model-install:
	@(echo -e "\033[31mInstalling model\033[0;0m")
	$(MAKE) -C model install
selector-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
model-clean:
	@(echo -e "\033[31mCleaning object from model\033[0;0m")
	$(MAKE) -C model clean
selector-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
model-mrproper:
	@(echo -e "\033[31mRuning mrproper on model\033[0;0m")
	$(MAKE) -C model mrproper
selector-phony: .PHONY
