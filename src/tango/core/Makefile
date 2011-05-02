ROOT_SRC_DIR       = ../../
IMPORT_DEST        = $(ROOT_SRC_DIR)../include
PACKAGE_PATH       = core/
PACKAGE_FULL_PATH  = $(IMPORT_DEST)/$(PACKAGE_PATH)
DFLAGS_REQ         = -I$(ROOT_SRC_DIR)
OBJ_PATH           = $(ROOT_SRC_DIR)../build
BUILD_PATH         = $(OBJ_PATH)/c/
SRC                = $(wicard *.d)
OBJ                = $(SRC:.d=.o)
build: rt-build sync-build tools-build vendor-build core-build
install:rt-install sync-install tools-install vendor-install core-install
clean: rt-clean sync-clean tools-clean vendor-clean core-clean
mrproper: rt-mrproper sync-mrproper tools-mrproper vendor-mrproper core-mrproper
.PHONY: clean mrproper core-mrproper core-clean
%.o: %.d
	$(DC) $(DFLAGS) $(DFLAGS_EXTRA) $(DFLAGS_REQ) $< $(HD)$(PACKAGE_FULL_PATH) $(OF)$(BUILD_PATH)$@
core-build: $(OBJ)
rt-build:
	@(echo -e "\033[31mBuilding rt\033[0;0m")
	$(MAKE) -C rt build
sync-build:
	@(echo -e "\033[31mBuilding sync\033[0;0m")
	$(MAKE) -C sync build
tools-build:
	@(echo -e "\033[31mBuilding tools\033[0;0m")
	$(MAKE) -C tools build
vendor-build:
	@(echo -e "\033[31mBuilding vendor\033[0;0m")
	$(MAKE) -C vendor build
core-install:
	@($(MKDIR) $(INCLUDEDIR)/$(PACKAGE_PATH))
	@($(CPR)   $(PACKAGE_FULL_PATH)/*.di $(INCLUDEDIR)/$(PACKAGE_PATH))
rt-install:
	@(echo -e "\033[31mInstalling rt\033[0;0m")
	$(MAKE) -C rt install
sync-install:
	@(echo -e "\033[31mInstalling sync\033[0;0m")
	$(MAKE) -C sync install
tools-install:
	@(echo -e "\033[31mInstalling tools\033[0;0m")
	$(MAKE) -C tools install
vendor-install:
	@(echo -e "\033[31mInstalling vendor\033[0;0m")
	$(MAKE) -C vendor install
core-clean:
	(cd $(OBJ_PATH); $(RMR) $(OBJ))
rt-clean:
	@(echo -e "\033[31mCleaning object from rt\033[0;0m")
	$(MAKE) -C rt clean
sync-clean:
	@(echo -e "\033[31mCleaning object from sync\033[0;0m")
	$(MAKE) -C sync clean
tools-clean:
	@(echo -e "\033[31mCleaning object from tools\033[0;0m")
	$(MAKE) -C tools clean
vendor-clean:
	@(echo -e "\033[31mCleaning object from vendor\033[0;0m")
	$(MAKE) -C vendor clean
core-mrproper:
	$(RMR) $(ROOT_SRC_DIR)$(PACKAGE_FULL_PATH)
rt-mrproper:
	$(MAKE) -C rt mrproper
sync-mrproper:
	$(MAKE) -C sync mrproper
tools-mrproper:
	$(MAKE) -C tools mrproper
vendor-mrproper:
	$(MAKE) -C vendor mrproper
