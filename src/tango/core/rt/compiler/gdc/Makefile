ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = gdc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/gdc/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: gdc-build gcc-build rt-build std-build typeinfo-build
install: gdc-install gcc-install rt-install std-install typeinfo-install
clean: gdc-clean gcc-clean rt-clean std-clean typeinfo-clean
mrproper: gdc-mrproper gcc-mrproper rt-mrproper std-mrproper typeinfo-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
gdc-build: $(OBJ)
gcc-build:
	@(echo -e "\033[31mBuilding gcc\033[0;0m")
	$(MAKE) -C gcc build
rt-build:
	@(echo -e "\033[31mBuilding rt\033[0;0m")
	$(MAKE) -C rt build
std-build:
	@(echo -e "\033[31mBuilding std\033[0;0m")
	$(MAKE) -C std build
typeinfo-build:
	@(echo -e "\033[31mBuilding typeinfo\033[0;0m")
	$(MAKE) -C typeinfo build
gdc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
gcc-install:
	@(echo -e "\033[31mInstalling gcc\033[0;0m")
	$(MAKE) -C gcc install
rt-install:
	@(echo -e "\033[31mInstalling rt\033[0;0m")
	$(MAKE) -C rt install
std-install:
	@(echo -e "\033[31mInstalling std\033[0;0m")
	$(MAKE) -C std install
typeinfo-install:
	@(echo -e "\033[31mInstalling typeinfo\033[0;0m")
	$(MAKE) -C typeinfo install
gdc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))

gdc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
gcc-clean:
	@(echo -e "\033[31mCleaning object from gcc\033[0;0m")
	$(MAKE) -C gcc clean
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
gcc-mrproper:
	@(echo -e "\033[31mRuning mrproper on gcc\033[0;0m")
	$(MAKE) -C gcc mrproper
rt-mrproper:
	@(echo -e "\033[31mRuning mrproper on rt\033[0;0m")
	$(MAKE) -C rt mrproper
std-mrproper:
	@(echo -e "\033[31mRuning mrproper on std\033[0;0m")
	$(MAKE) -C std mrproper
typeinfo-mrproper:
	@(echo -e "\033[31mRuning mrproper on typeinfo\033[0;0m")
	$(MAKE) -C typeinfo mrproper
gdc-phony: .PHONY
