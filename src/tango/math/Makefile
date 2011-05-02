ROOT_SRC_DIR       = ../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = math/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: math-build internal-build random-build
install: math-install internal-install random-install
clean: math-clean internal-clean random-clean
mrproper: math-mrproper internal-mrproper random-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
math-build: $(OBJ)
internal-build:
	@(echo -e "\033[31mBuilding internal\033[0;0m")
	$(MAKE) -C internal build
random-build:
	@(echo -e "\033[31mBuilding random\033[0;0m")
	$(MAKE) -C random build
math-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
internal-install:
	@(echo -e "\033[31mInstalling internal\033[0;0m")
	$(MAKE) -C internal install
random-install:
	@(echo -e "\033[31mInstalling random\033[0;0m")
	$(MAKE) -C random install
math-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
internal-clean:
	@(echo -e "\033[31mCleaning object from internal\033[0;0m")
	$(MAKE) -C internal clean
random-clean:
	@(echo -e "\033[31mCleaning object from random\033[0;0m")
	$(MAKE) -C random clean
math-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
internal-mrproper:
	@(echo -e "\033[31mRuning mrproper on internal\033[0;0m")
	$(MAKE) -C internal mrproper
random-mrproper:
	@(echo -e "\033[31mRuning mrproper on random\033[0;0m")
	$(MAKE) -C random mrproper
math-phony: .PHONY
