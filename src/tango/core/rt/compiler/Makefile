ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = compiler/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: dmd-build gdc-build ldc-build util-build
install: dmd-install gdc-install ldc-install util-install
clean: dmd-clean gdc-clean ldc-clean util-clean
mrproper: dmd-mrproper gdc-mrproper ldc-mrproper util-mrproper
.PHONY: clean mrproper
dmd-build:
	@(echo -e "\033[31mBuilding dmd\033[0;0m")
	$(MAKE) -C dmd build
gdc-build:
	@(echo -e "\033[31mBuilding gdc\033[0;0m")
	$(MAKE) -C gdc build
ldc-build:
	@(echo -e "\033[31mBuilding ldc\033[0;0m")
	$(MAKE) -C ldc build
util-build:
	@(echo -e "\033[31mBuilding util\033[0;0m")
	$(MAKE) -C util build
dmd-install:
	@(echo -e "\033[31mInstalling dmd\033[0;0m")
	$(MAKE) -C dmd install
gdc-install:
	@(echo -e "\033[31mInstalling gdc\033[0;0m")
	$(MAKE) -C gdc install
ldc-install:
	@(echo -e "\033[31mInstalling ldc\033[0;0m")
	$(MAKE) -C ldc install
util-install:
	@(echo -e "\033[31mInstalling util\033[0;0m")
	$(MAKE) -C util install
dmd-clean:
	@(echo -e "\033[31mCleaning object from dmd\033[0;0m")
	$(MAKE) -C dmd clean
gdc-clean:
	@(echo -e "\033[31mCleaning object from gdc\033[0;0m")
	$(MAKE) -C gdc clean
ldc-clean:
	@(echo -e "\033[31mCleaning object from ldc\033[0;0m")
	$(MAKE) -C ldc clean
util-clean:
	@(echo -e "\033[31mCleaning object from util\033[0;0m")
	$(MAKE) -C util clean
dmd-mrproper:
	@(echo -e "\033[31mRuning mrproper on dmd\033[0;0m")
	$(MAKE) -C dmd mrproper
gdc-mrproper:
	@(echo -e "\033[31mRuning mrproper on gdc\033[0;0m")
	$(MAKE) -C gdc mrproper
ldc-mrproper:
	@(echo -e "\033[31mRuning mrproper on ldc\033[0;0m")
	$(MAKE) -C ldc mrproper
util-mrproper:
	@(echo -e "\033[31mRuning mrproper on util\033[0;0m")
	$(MAKE) -C util mrproper
dmd-phony:
	@(echo -e "\033[31mRuning .PHONY on dmd\033[0;0m")
	$(MAKE) -C dmd phony
gdc-phony:
	@(echo -e "\033[31mRuning .PHONY on gdc\033[0;0m")
	$(MAKE) -C gdc phony
ldc-phony:
	@(echo -e "\033[31mRuning .PHONY on ldc\033[0;0m")
	$(MAKE) -C ldc phony
util-phony:
	@(echo -e "\033[31mRuning .PHONY on util\033[0;0m")
	$(MAKE) -C util phony
