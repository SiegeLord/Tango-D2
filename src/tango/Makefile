ROOT_SRC_DIR       = ../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = tango/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: core-build io-build math-build net-build stdc-build sys-build text-build time-build util-build
install: core-install io-install math-install net-install stdc-install sys-install text-install time-install util-install
clean: core-clean io-clean math-clean net-clean stdc-clean sys-clean text-clean time-clean util-clean
mrproper: core-mrproper io-mrproper math-mrproper net-mrproper stdc-mrproper sys-mrproper text-mrproper time-mrproper util-mrproper
.PHONY: clean mrproper
core-build:
	@(echo -e "\033[31mBuilding core\033[0;0m")
	$(MAKE) -C core build
io-build:
	@(echo -e "\033[31mBuilding io\033[0;0m")
	$(MAKE) -C io build
math-build:
	@(echo -e "\033[31mBuilding math\033[0;0m")
	$(MAKE) -C math build
net-build:
	@(echo -e "\033[31mBuilding net\033[0;0m")
	$(MAKE) -C net build
stdc-build:
	@(echo -e "\033[31mBuilding stdc\033[0;0m")
	$(MAKE) -C stdc build
sys-build:
	@(echo -e "\033[31mBuilding sys\033[0;0m")
	$(MAKE) -C sys build
text-build:
	@(echo -e "\033[31mBuilding text\033[0;0m")
	$(MAKE) -C text build
time-build:
	@(echo -e "\033[31mBuilding time\033[0;0m")
	$(MAKE) -C time build
util-build:
	@(echo -e "\033[31mBuilding util\033[0;0m")
	$(MAKE) -C util build
core-install:
	@(echo -e "\033[31mInstalling core\033[0;0m")
	$(MAKE) -C core install
io-install:
	@(echo -e "\033[31mInstalling io\033[0;0m")
	$(MAKE) -C io install
math-install:
	@(echo -e "\033[31mInstalling math\033[0;0m")
	$(MAKE) -C math install
net-install:
	@(echo -e "\033[31mInstalling net\033[0;0m")
	$(MAKE) -C net install
stdc-install:
	@(echo -e "\033[31mInstalling stdc\033[0;0m")
	$(MAKE) -C stdc install
sys-install:
	@(echo -e "\033[31mInstalling sys\033[0;0m")
	$(MAKE) -C sys install
text-install:
	@(echo -e "\033[31mInstalling text\033[0;0m")
	$(MAKE) -C text install
time-install:
	@(echo -e "\033[31mInstalling time\033[0;0m")
	$(MAKE) -C time install
util-install:
	@(echo -e "\033[31mInstalling util\033[0;0m")
	$(MAKE) -C util install
core-clean:
	@(echo -e "\033[31mCleaning core\033[0;0m")
	$(MAKE) -C core clean
io-clean:
	@(echo -e "\033[31mCleaning io\033[0;0m")
	$(MAKE) -C io clean
math-clean:
	@(echo -e "\033[31mCleaning math\033[0;0m")
	$(MAKE) -C math clean
net-clean:
	@(echo -e "\033[31mCleaning net\033[0;0m")
	$(MAKE) -C net clean
stdc-clean:
	@(echo -e "\033[31mCleaning stdc\033[0;0m")
	$(MAKE) -C stdc clean
sys-clean:
	@(echo -e "\033[31mCleaning sys\033[0;0m")
	$(MAKE) -C sys clean
text-clean:
	@(echo -e "\033[31mCleaning text\033[0;0m")
	$(MAKE) -C text clean
time-clean:
	@(echo -e "\033[31mCleaning time\033[0;0m")
	$(MAKE) -C time clean
util-clean:
	@(echo -e "\033[31mCleaning util\033[0;0m")
	$(MAKE) -C util clean
core-mrproper:
	@(echo -e "\033[31mMrproper core\033[0;0m")
	$(MAKE) -C core mrproper
io-mrproper:
	@(echo -e "\033[31mMrproper io\033[0;0m")
	$(MAKE) -C io mrproper
math-mrproper:
	@(echo -e "\033[31mMrproper math\033[0;0m")
	$(MAKE) -C math mrproper
net-mrproper:
	@(echo -e "\033[31mMrproper net\033[0;0m")
	$(MAKE) -C net mrproper
stdc-mrproper:
	@(echo -e "\033[31mMrproper stdc\033[0;0m")
	$(MAKE) -C stdc mrproper
sys-mrproper:
	@(echo -e "\033[31mMrproper sys\033[0;0m")
	$(MAKE) -C sys mrproper
text-mrproper:
	@(echo -e "\033[31mMrproper text\033[0;0m")
	$(MAKE) -C text mrproper
time-mrproper:
	@(echo -e "\033[31mMrproper time\033[0;0m")
	$(MAKE) -C time mrproper
util-mrproper:
	@(echo -e "\033[31mMrproper util\033[0;0m")
	$(MAKE) -C util mrproper
