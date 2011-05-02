ROOT_SRC_DIR       = ../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = net/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/net/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: net-build device-build ftp-build http-build model-build util-build
install: net-install device-install ftp-install http-install model-install util-install
clean: net-clean device-clean ftp-clean http-clean model-clean util-clean
mrproper: net-mrproper device-mrproper ftp-mrproper http-mrproper model-mrproper util-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
net-build: $(OBJ)
device-build:
	@(echo -e "\033[31mBuilding device\033[0;0m")
	$(MAKE) -C device build
ftp-build:
	@(echo -e "\033[31mBuilding ftp\033[0;0m")
	$(MAKE) -C ftp build
http-build:
	@(echo -e "\033[31mBuilding http\033[0;0m")
	$(MAKE) -C http build
model-build:
	@(echo -e "\033[31mBuilding model\033[0;0m")
	$(MAKE) -C model build
util-build:
	@(echo -e "\033[31mBuilding util\033[0;0m")
	$(MAKE) -C util build
net-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
device-install:
	@(echo -e "\033[31mInstalling device\033[0;0m")
	$(MAKE) -C device install
ftp-install:
	@(echo -e "\033[31mInstalling ftp\033[0;0m")
	$(MAKE) -C ftp install
http-install:
	@(echo -e "\033[31mInstalling http\033[0;0m")
	$(MAKE) -C http install
model-install:
	@(echo -e "\033[31mInstalling model\033[0;0m")
	$(MAKE) -C model install
util-install:
	@(echo -e "\033[31mInstalling util\033[0;0m")
	$(MAKE) -C util install
net-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
device-clean :
	@(echo -e "\033[31mCleaning object from device\033[0;0m")
	$(MAKE) -C device clean
ftp-clean:
	@(echo -e "\033[31mCleaning object from ftp\033[0;0m")
	$(MAKE) -C ftp clean
http-clean:
	@(echo -e "\033[31mCleaning object from http\033[0;0m")
	$(MAKE) -C http clean
model-clean:
	@(echo -e "\033[31mCleaning object from model\033[0;0m")
	$(MAKE) -C model clean
util-clean:
	@(echo -e "\033[31mCleaning object from util\033[0;0m")
	$(MAKE) -C util clean
net-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
device-mrproper:
	@(echo -e "\033[31mRuning mrproper on device\033[0;0m")
	$(MAKE) -C device mrproper
ftp-mrproper:
	@(echo -e "\033[31mRuning mrproper on ftp\033[0;0m")
	$(MAKE) -C ftp mrproper
http-mrproper:
	@(echo -e "\033[31mRuning mrproper on http\033[0;0m")
	$(MAKE) -C http mrproper
model-mrproper:
	@(echo -e "\033[31mRuning mrproper on model\033[0;0m")
	$(MAKE) -C model mrproper
util-mrproper:
	@(echo -e "\033[31mRuning mrproper on util\033[0;0m")
	$(MAKE) -C util mrproper
net-phony: .PHONY
