ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = random/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: random-build engines-build
install: random-install engines-install
clean: random-clean engines-clean
mrproper: random-mrproper engines-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
random-build: $(OBJ)
engines-build:
	@(echo -e "\033[31mBuilding engines\033[0;0m")
	$(MAKE) -C engines build
random-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
engines-install:
	@(echo -e "\033[31mInstalling engines\033[0;0m")
	$(MAKE) -C engines install
random-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
engines-clean:
	@(echo -e "\033[31mCleaning object from engines\033[0;0m")
	$(MAKE) -C engines clean
random-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
engines-mrproper:
	@(echo -e "\033[31mRuning mrproper on engines\033[0;0m")
	$(MAKE) -C engines mrproper
random-phony: .PHONY
