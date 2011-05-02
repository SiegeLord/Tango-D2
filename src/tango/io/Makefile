ROOT_SRC_DIR       = ../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = io/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: io-build device-build model-build selector-build stream-build vfs-build
install: io-install device-install model-install selector-install stream-install vfs-install
clean: io-clean device-clean model-clean selector-clean stream-clean vfs-clean
mrproper: io-mrproper device-mrproper model-mrproper selector-mrproper stream-mrproper vfs-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
io-build: $(OBJ)
device-build:
	@(echo -e "\033[31mBuilding device\033[0;0m")
	$(MAKE) -C device build
model-build:
	@(echo -e "\033[31mBuilding model\033[0;0m")
	$(MAKE) -C model build
selector-build:
	@(echo -e "\033[31mBuilding selector\033[0;0m")
	$(MAKE) -C selector build
stream-build:
	@(echo -e "\033[31mBuilding stream\033[0;0m")
	$(MAKE) -C stream build
vfs-build:
	@(echo -e "\033[31mBuilding vfs\033[0;0m")
	$(MAKE) -C vfs build
io-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
device-install:
	@(echo -e "\033[31mInstalling device\033[0;0m")
	$(MAKE) -C device install
model-install:
	@(echo -e "\033[31mInstalling model\033[0;0m")
	$(MAKE) -C model install
selector-install:
	@(echo -e "\033[31mInstalling selector\033[0;0m")
	$(MAKE) -C selector install
stream-install:
	@(echo -e "\033[31mInstalling stream\033[0;0m")
	$(MAKE) -C stream install
vfs-install:
	@(echo -e "\033[31mInstalling vfs\033[0;0m")
	$(MAKE) -C vfs install
io-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
device-clean:
	@(echo -e "\033[31mCleaning object from device\033[0;0m")
	$(MAKE) -C device clean
model-clean:
	@(echo -e "\033[31mCleaning object from model\033[0;0m")
	$(MAKE) -C model clean
selector-clean:
	@(echo -e "\033[31mCleaning object from selector\033[0;0m")
	$(MAKE) -C selector clean
stream-clean:
	@(echo -e "\033[31mCleaning object from stream\033[0;0m")
	$(MAKE) -C stream clean
vfs-clean:
	@(echo -e "\033[31mCleaning object from vfs\033[0;0m")
	$(MAKE) -C vfs clean
io-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
device-mrproper:
	@(echo -e "\033[31mRuning mrproper on device\033[0;0m")
	$(MAKE) -C device mrproper
model-mrproper:
	@(echo -e "\033[31mRuning mrproper on model\033[0;0m")
	$(MAKE) -C model mrproper
selector-mrproper:
	@(echo -e "\033[31mRuning mrproper on selector\033[0;0m")
	$(MAKE) -C selector mrproper
stream-mrproper:
	@(echo -e "\033[31mRuning mrproper on stream\033[0;0m")
	$(MAKE) -C stream mrproper
vfs-mrproper:
	@(echo -e "\033[31mRuning mrproper on c\033[0;0m")
	$(MAKE) -C vfs mrproper
io-phony: .PHONY
