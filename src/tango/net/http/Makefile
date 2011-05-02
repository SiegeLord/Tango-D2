ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = http/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: http-build model-build
install: http-install model-install
clean: http-clean model-clean
mrproper: http-mrproper model-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
http-build: $(OBJ)
model-build:
	@(echo -e "\033[31mBuilding model\033[0;0m")
	$(MAKE) -C model build
http-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
model-install:
	@(echo -e "\033[31mInstalling model\033[0;0m")
	$(MAKE) -C model install
http-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
model-clean:
	@(echo -e "\033[31mCleaning object from model\033[0;0m")
	$(MAKE) -C model clean
http-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
model-mrproper:
	@(echo -e "\033[31mRuning mrproper on model\033[0;0m")
	$(MAKE) -C model mrproper
http-phony: .PHONY
