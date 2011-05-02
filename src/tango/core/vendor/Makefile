ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = vendor/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/vendor/
SRC                = $(wivendorard *.d)
OBJ                = $(SRC:.d=.o)
build: gdc-build ldc-build std-build
install: gdc-install ldc-install std-install
clean: gdc-clean ldc-clean std-clean
mrproper: gdc-mrproper ldc-mrproper std-mrproper
.PHONY: clean mrproper
gdc-build:
	@(echo -e "\033[31mBuilding gdc\033[0;0m")
	$(MAKE) -C gdc build
ldc-build:
	@(echo -e "\033[31mBuilding ldc\033[0;0m")
	$(MAKE) -C ldc build
std-build:
	@(echo -e "\033[31mBuilding std\033[0;0m")
	$(MAKE) -C std build
gdc-install:
	@(echo -e "\033[31mInstalling gdc\033[0;0m")
	$(MAKE) -C gdc install
ldc-install:
	@(echo -e "\033[31mInstalling ldc\033[0;0m")
	$(MAKE) -C ldc install
std-install:
	@(echo -e "\033[31mInstalling std\033[0;0m")
	$(MAKE) -C std install
gdc-clean:
	@(echo -e "\033[31mCleaning object from gdc\033[0;0m")
	$(MAKE) -C gdc clean
ldc-clean:
	@(echo -e "\033[31mCleaning object from ldc\033[0;0m")
	$(MAKE) -C ldc clean
std-clean:
	@(echo -e "\033[31mCleaning object from std\033[0;0m")
	$(MAKE) -C std clean
gdc-mrproper:
	@(echo -e "\033[31mRuning mrproper on gdc\033[0;0m")
	$(MAKE) -C gdc mrproper
ldc-mrproper:
	@(echo -e "\033[31mRuning mrproper on ldc\033[0;0m")
	$(MAKE) -C ldc mrproper
std-mrproper:
	@(echo -e "\033[31mRuning mrproper on std\033[0;0m")
	$(MAKE) -C std mrproper
gdc-phony:
	@(echo -e "\033[31mRuning .PHONY on gdc\033[0;0m")
	$(MAKE) -C gdc phony
ldc-phony:
	@(echo -e "\033[31mRuning .PHONY on ldc\033[0;0m")
	$(MAKE) -C ldc phony
std-phony:
	@(echo -e "\033[31mRuning .PHONY on std\033[0;0m")
	$(MAKE) -C std phony
