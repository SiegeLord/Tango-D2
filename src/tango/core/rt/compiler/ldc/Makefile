ROOT_SRC_DIR       = ../../../../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = ldc/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/ldc/
SRC                = $(wildcard *.d)
OBJ                = $(SRC:.d=.o)
build: ldc-build rt-build typeinfo-build
install: ldc-install rt-install typeinfo-install
clean: ldc-clean rt-clean typinfo-clen
mrproper: ldc-mrproper rt-mrproprt typeinfo-mrproper
.PHONY: clean mrproper
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
ldc-build: $(OBJ)
rt-build:
	@(echo -e "\033[31mBuilding rt\033[0;0m")
	$(MAKE) -C rt build
typeinfo-build:
	@(echo -e "\033[31mBuilding typeinfo\033[0;0m")
	$(MAKE) -C typeinfo build
ldc-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
rt-install:
	@(echo -e "\033[31mInstalling rt\033[0;0m")
	$(MAKE) -C rt install
typeinfo-install:
	@(echo -e "\033[31mInstalling typeinfo\033[0;0m")
	$(MAKE) -C typeinfo install
ldc-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
rt-clean:
	@(echo -e "\033[31mCleaning object from rt\033[0;0m")
	$(MAKE) -C rt clean
typeinfo-clean:
	@(echo -e "\033[31mCleaning object from typeinfo\033[0;0m")
	$(MAKE) -C typeinfo clean
ldc-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
rt-mrproper:
	@(echo -e "\033[31mRuning mrproper on rt\033[0;0m")
	$(MAKE) -C rt mrproper
typeinfo-mrproper:
	@(echo -e "\033[31mRuning mrproper on typeinfo\033[0;0m")
	$(MAKE) -C typeinfo mrproper
ldc-phony: .PHONY
