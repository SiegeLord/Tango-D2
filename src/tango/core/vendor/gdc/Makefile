ROOT_SRC_DIR       = ../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = gdc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/gdc/
SRC                = $(wigdcard *.d)
OBJ                = $(SRC:.d=.o)
build: c-build
install: c-install
clean: c-clean
mrproper: c-mrproper
.PHONY: clean mrproper
c-build:
	@(echo -e "\033[31mBuilding c\033[0;0m")
	$(MAKE) -C c build
c-install:
	@(echo -e "\033[31mInstalling c\033[0;0m")
	$(MAKE) -C c install
c-clean:
	@(echo -e "\033[31mCleaning object from c\033[0;0m")
	$(MAKE) -C c clean
c-mrproper:
	@(echo -e "\033[31mRuning mrproper on c\033[0;0m")
	$(MAKE) -C c mrproper
gdc-phony: .PHONY
c-phony:
	@(echo -e "\033[31mRuning .PHONY on c\033[0;0m")
	$(MAKE) -C c phony

