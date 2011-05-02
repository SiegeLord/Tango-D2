ROOT_SRC_DIR       = ../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = rt/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: compiler-build gc-build
install:compiler-install gc-install
clean: compiler-clean gc-clean
mrproper: compiler-mrproper gc-mrproper
.PHONY: clean mrproper
compiler-build:
	@(echo -e "\033[31mBuilding compiler\033[0;0m")
	$(MAKE) -C compiler build
gc-build:
	@(echo -e "\033[31mBuilding gc\033[0;0m")
	$(MAKE) -C gc build
compiler-install:
	@(echo -e "\033[31mInstalling compiler\033[0;0m")
	$(MAKE) -C compiler install
gc-install:
	@(echo -e "\033[31mInstalling gc\033[0;0m")
	$(MAKE) -C gc install
clean: compiler-clean gc-clean
complier-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
gc-clean:
	@(echo -e "\033[31mCleaning object from gc\033[0;0m")
	$(MAKE) -C rt clean
mrproper: compiler-mrproper gc-mrproper
compiler-mrproper:
	$(MAKE) -C compiler mrproper
gc-mrproper:
	$(MAKE) -C gc mrproper
compiler-phony:
	@(echo -e "\033[31mRuning .PHONY on compiler\033[0;0m")
	$(MAKE) -C compiler phony
gc-phony:
	@(echo -e "\033[31mRuning .PHONY on gc\033[0;0m")
	$(MAKE) -C gc phony
