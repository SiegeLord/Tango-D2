ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = dmd/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/dmd/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: dmd-build darwin-build posix-build rt-build std-build typeinfo-build windows-build
install: dmd-install darwin-install posix-install rt-install std-install typeinfo-install windows-install
clean:  dmd-clean darwin-clean posix-clean rt-clean std-clean typeinfo-clean windows-clean
mrproper: dmd-mrproper darwin-mrproper posix-mrproper rt-mrproper std-mrproper typeinfo-mrproper windows-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
dmd-build: $(OBJ)
darwin-build:
	@(echo -e "\033[31mBuilding darwin\033[0;0m")
	$(MAKE) -C darwin build
posix-build:
	@(echo -e "\033[31mBuilding posix\033[0;0m")
	$(MAKE) -C posix build
rt-build:
	@(echo -e "\033[31mBuilding rt\033[0;0m")
	$(MAKE) -C rt build
std-build:
	@(echo -e "\033[31mBuilding std\033[0;0m")
	$(MAKE) -C std build
typeinfo-build:
	@(echo -e "\033[31mBuilding typeinfo\033[0;0m")
	$(MAKE) -C typeinfo build
windows-build:
	@(echo -e "\033[31mBuilding windows\033[0;0m")
	$(MAKE) -C dmd build
dmd-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
darwin-install:
	@(echo -e "\033[31mInstalling darwin\033[0;0m")
	$(MAKE) -C darwin install
posix-install:
	@(echo -e "\033[31mInstalling posix\033[0;0m")
	$(MAKE) -C posix install
rt-install:
	@(echo -e "\033[31mInstalling rt\033[0;0m")
	$(MAKE) -C rt install
std-install:
	@(echo -e "\033[31mInstalling std\033[0;0m")
	$(MAKE) -C std install
typeinfo-install:
	@(echo -e "\033[31mInstalling typeinfo\033[0;0m")
	$(MAKE) -C typeinfo install
windows-install:
	@(echo -e "\033[31mInstalling windows\033[0;0m")
	$(MAKE) -C dmd install
dmd-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
darwin-clean:
	@(echo -e "\033[31mCleaning object from darwin\033[0;0m")
	$(MAKE) -C darwin clean
posix-clean:
	@(echo -e "\033[31mCleaning object from posix\033[0;0m")
	$(MAKE) -C posix clean
rt-clean:
	@(echo -e "\033[31mCleaning object from rt\033[0;0m")
	$(MAKE) -C rt clean
std-clean:
	@(echo -e "\033[31mCleaning object from std\033[0;0m")
	$(MAKE) -C std clean
typeinfo-clean:
	@(echo -e "\033[31mCleaning object from typeinfo\033[0;0m")
	$(MAKE) -C typeinfo clean
windows-clean:
	@(echo -e "\033[31mCleaning object from windows\033[0;0m")
	$(MAKE) -C dmd clean
dmd-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
darwin-mrproper:
	@(echo -e "\033[31mRuning mrproper on darwin\033[0;0m")
	$(MAKE) -C darwin mrproper
posix-mrproper:
	@(echo -e "\033[31mRuning mrproper on posix\033[0;0m")
	$(MAKE) -C posix mrproper
rt-mrproper:
	@(echo -e "\033[31mRuning mrproper on rt\033[0;0m")
	$(MAKE) -C rt mrproper
std-mrproper:
	@(echo -e "\033[31mRuning mrproper on std\033[0;0m")
	$(MAKE) -C std mrproper
typeinfo-mrproper:
	@(echo -e "\033[31mRuning mrproper on typeinfo\033[0;0m")
	$(MAKE) -C typeinfo mrproper
windows-mrproper:
	@(echo -e "\033[31mRuning mrproper on windows\033[0;0m")
	$(MAKE) -C dmd mrproper
dmd-phony: .PHONY
