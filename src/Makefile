export INCLUDEDIR  = /usr/include/d
export LIBDIR      = /usr/lib/
export CP          = cp -f
export CPR         = cp -r
export RM          = rm -f
export RMR         = rm -rf
export MKDIR       = mkdir -p
export LIB_EXT     = a
export LIB_PRE     = lib
export DC          = ldc
export MAKE        = make
export AR          = ar
export ARFLAGS     = rcs
export RANLIB      = ranlib
export DFLAGS      = -g -O -op -inline
export DFLAGS_EXTRA= -release -c
configFile         = ""
ifeq ($(DC), ldc2)
	configFile = ldc-properties.make
else ifeq ($(DC), ldc)
	configFile = ldc-properties.make
else ifeq ($(DC), dmd2)
	configFile = dmd-properties.make
else ifeq ($(DC), dmd)
	configFile = dmd-properties.make
else ifeq ($(DC), gdc)
	configFile = gdmd-properties.make
else ifeq ($(DC), gdmd)
	configFile = gdmd-properties.make
endif
include $(configFile)
IMPORT_DEST        = ./include
DLIB_PATH          = ./lib
ROOT_SRC_DIR       = ./
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = 
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/
build: tango-build executable
install: tango-install
clean: tango-clean
mrproper: tango-mrproper
.PHONY: clean mrproper
tango-build:
	@(echo -e "\033[31mBuilding tango\033[0;0m")
	$(MAKE) -C tango build
tango-install:
	@(echo -e "\033[31mInstalling tango\033[0;0m")
	$(MAKE) -C tango install
tango-clean:
	@(echo -e "\033[31mCleaning object from tango\033[0;0m")
	$(MAKE) -C tango clean
tango-mrproper:
	@(echo -e "\033[31mNothing to do for tango\033[0;0m")
tango-phony:
	@(echo -e "\033[31mRuning .PHONY on tango\033[0;0m")
	$(MAKE) -C tango phony
executable:
	@(echo -e "\033[31mBuilding executable\033[0;0m")
	$(DC) $(OBJ_PATH)/tango/*.o  -of../bin/tango
