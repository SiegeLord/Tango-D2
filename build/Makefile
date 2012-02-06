
export PROJECT_NAME     = tango
export AUTHOR           = Tango contributors
export DESCRIPTION      =
export VERSION          = 2
export LICENSE          = ACL v3
SOURCES                 = $(filter-out $(Filter), $(getSource))

DDOCFILES               =

# include some command
include build/command.make

OBJECTS             = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o,    $(SOURCES))
PICOBJECTS          = $(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.pic.o,$(SOURCES))
HEADERS             = $(patsubst %.d,$(IMPORT_PATH)$(PATH_SEP)%.di,  $(SOURCES))
PLAIN_DOC_FILES          = $(patsubst %.d,$(PLAIN_DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
DOC_FILES     = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))
define make-lib
	$(MKDIR) $(DLIB_PATH)
	$(AR) rcs $(DLIB_PATH)$(PATH_SEP)$@ $^
	$(RANLIB) $(DLIB_PATH)$(PATH_SEP)$@
endef

############# BUILD #############
all: static-lib header plain-doc pkgfile-static
	@echo ------------------ Building $^ done
all-shared: static-shared header plain-doc pkgfile-shared
	@echo ------------------ Building $^ done

.PHONY : pkgfile
.PHONY : plain-doc
.PHONY : doc
.PHONY : clean

static-lib: $(LIBNAME)

shared-lib: $(SONAME)

header: $(HEADERS)
	@echo ------------------ Building headers done

plain-doc: $(PLAIN_DOC_FILES)
	@echo ------------------ Building plain documentation done

doc: $(DOC_FILES)
	$(DC) $(DDOC_FLAGS) $(DVERSION)=TangoDoc index.d $(DF)$(DOC_PATH)$(PATH_SEP)index.html
	@echo ------------------ Building documentation done

geany-tag:
	@echo ------------------ Building geany tag
	$(MKDIR) geany_config
	geany -c geany_config -g $(PROJECT_NAME).d.tags $(SOURCES)

pkgfile-shared:
	@echo ------------------ Building pkg-config file
	@echo "# Package Information for pkg-config"                        >  $(PKG_CONFIG_FILE)
	@echo "# Author: $(AUTHOR)"                                         >> $(PKG_CONFIG_FILE)
	@echo "# Created: `date`"                                           >> $(PKG_CONFIG_FILE)
	@echo "# Licence: $(LICENSE)"                                       >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo prefix=$(PREFIX)                                              >> $(PKG_CONFIG_FILE)
	@echo exec_prefix=$(PREFIX)                                         >> $(PKG_CONFIG_FILE)
	@echo libdir=$(LIB_DIR)                                             >> $(PKG_CONFIG_FILE)
	@echo includedir=$(INCLUDE_DIR)sqlite                               >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo Name: "$(PROJECT_NAME)"                                       >> $(PKG_CONFIG_FILE)
	@echo Description: "$(DESCRIPTION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Version: "$(VERSION)"                                         >> $(PKG_CONFIG_FILE)
	@echo Libs: $(LINKERFLAG)-l$(PROJECT_NAME)-$(COMPILER)              >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)sqlite $(LDCFLAGS)                    >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)

pkgfile-static:
	@echo ------------------ Building pkg-config file
	@echo "# Package Information for pkg-config"                        >  $(PKG_CONFIG_FILE)
	@echo "# Author: $(AUTHOR)"                                         >> $(PKG_CONFIG_FILE)
	@echo "# Created: `date`"                                           >> $(PKG_CONFIG_FILE)
	@echo "# Licence: $(LICENSE)"                                       >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo prefix=$(PREFIX)                                              >> $(PKG_CONFIG_FILE)
	@echo exec_prefix=$(PREFIX)                                         >> $(PKG_CONFIG_FILE)
	@echo libdir=$(LIB_DIR)                                             >> $(PKG_CONFIG_FILE)
	@echo includedir=$(INCLUDE_DIR)sqlite                               >> $(PKG_CONFIG_FILE)
	@echo                                                               >> $(PKG_CONFIG_FILE)
	@echo Name: "$(PROJECT_NAME)"                                       >> $(PKG_CONFIG_FILE)
	@echo Description: "$(DESCRIPTION)"                                 >> $(PKG_CONFIG_FILE)
	@echo Version: "$(VERSION)"                                         >> $(PKG_CONFIG_FILE)
	@echo Libs: $(LIB_DIR)$(PATH_SEP)$(LIBNAME)                         >> $(PKG_CONFIG_FILE)
	@echo Cflags: -I$(INCLUDE_DIR)$(PATH_SEP)$(PROJECT_NAME) $(LDCFLAGS)>> $(PKG_CONFIG_FILE)
	@echo

############# MKDIR #############
$(BUILD_PATH):
	test -d $(BUILD_PATH) || $(MKDIR) $(BUILD_PATH)
$(IMPORT_PATH):
	test -d $(IMPORT_PATH) || $(MKDIR) $(IMPORT_PATH)
$(DLIB_PATH):
	test -d $(DLIB_PATH) || $(MKDIR) $(DLIB_PATH)
$(PLAIN_DOC_PATH):
	test -d $(PLAIN_DOC_PATH) || $(MKDIR) $(PLAIN_DOC_PATH)
#~ $(DOC_PATH):
	#~ test -d $(DOC_PATH) || $(MKDIR) $(DOC_PATH)


############# BUILD #############


# For build lib need create object files and after run make-lib
$(LIBNAME): $(OBJECTS)
	@echo ------------------ Building static library
	$(make-lib)

# For build shared lib need create shared object files
$(SONAME): $(PICOBJECTS)
	@echo ------------------ Building shared library
	$(DC) -shared $(OUTPUT)$(DLIB_PATH)$(PATH_SEP)$@.$(VERSION) $^
	#~ $(CC) -shared -Wl,-soname,$@.$(VERSION) -o $(DLIB_PATH)$(PATH_SEP)$@.$(VERSION) $^

# create object files
$(BUILD_PATH)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# create shared object files
$(BUILD_PATH)$(PATH_SEP)%.pic.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(FPIC) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)$(PATH_SEP)%.di : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $< $(HF)$@

# Generate Documentation
$(PLAIN_DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) $(DVERSION)=TangoDoc -c $(NO_OBJ)  $< $(DF)$@

# Generate doc Documentation
$(DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) $(DVERSION)=TangoDoc -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@

############# CLEAN #############
clean: clean-objects clean-static-lib clean-plain-doc clean-header clean-pkgfile
	@echo ------------------ Cleaning $^ done

clean-shared: clean-shared-objects clean-shared-lib
	@echo ------------------ Cleaning $^ done

clean-objects:
	$(RM) $(OBJECTS)
	@echo ------------------ Cleaning objects done

clean-shared-objects:
	$(RM) $(PICOBJECTS)
	@echo ------------------ Cleaning shared-object done

clean-static-lib:
	$(RM) $(DLIB_PATH)$(PATH_SEP)$(LIBNAME)
	@echo ------------------ Cleaning static-lib done

clean-shared-lib:
	$(RM)  $(DLIB_PATH)$(PATH_SEP)$(SONAME).$(VERSION)
	@echo ------------------ Cleaning shared-lib done

clean-header:
	$(RM) $(HEADERS)
	@echo ------------------ Cleaning header done

clean-plain-doc:
	$(RM) $(PLAIN_DOC_FILES)
	@echo ------------------ Cleaning plain-doc done

clean-doc:
	$(RM) $(DOC_PATH)$(PATH_SEP)index.html
	@echo ------------------ Cleaning doc done

clean-geany-tag:
	$(RM) geany_config $(PROJECT_NAME).d.tags
	@echo ------------------ Cleaning geany tag done

clean-pkgfile:
	$(RM) $(PKG_CONFIG_FILE)
	@echo ------------------ Cleaning pkgfile done

############# INSTALL #############

install: install-static-lib install-plain-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-shared: install-shared-lib install-plain-doc install-header install-pkgfile
	@echo ------------------ Installing $^ done

install-static-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(LIBNAME) $(DESTDIR)$(LIB_DIR)
	@echo ------------------ Installing static-lib done

install-shared-lib:
	$(MKDIR) $(LIB_DIR)
	$(CP) $(DLIB_PATH)$(PATH_SEP)$(SONAME) $(DESTDIR)$(LIB_DIR)
	ln -s $(DESTDIR)$(LIB_DIR)$(SONAME).$(SO_VERSION)   $(DESTDIR)$(LIB_DIR)$(PATH_SEP)$(SONAME)
	@echo ------------------ Installing shared-lib done

install-header:
	$(MKDIR) $(INCLUDE_DIR)
	$(CP) $(IMPORT_PATH)$(PATH_SEP)$(PROJECT_NAME) $(DESTDIR)$(INCLUDE_DIR)
	@echo ------------------ Installing header done

install-modules:
	$(MKDIR) $(INCLUDE_DIR)
	$(CP) tango $(DESTDIR)$(INCLUDE_DIR)
	@echo ------------------ Installing header done

install-plain-doc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)plain_doc$(PATH_SEP)
	$(CP) $(PLAIN_DOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)plain_doc$(PATH_SEP)
	@echo ------------------ Installing doc done

install-doc:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)doc$(PATH_SEP)
	$(CP) $(DOC_PATH)$(PATH_SEP)* $(DESTDIR)$(DATA_DIR)$(PATH_SEP)doc$(PATH_SEP)$(PROJECT_NAME)$(PATH_SEP)doc$(PATH_SEP)
	@echo ------------------ Installing doc done

install-geany-tag:
	$(MKDIR) $(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	$(CP) $(PROJECT_NAME).d.tags $(DESTDIR)$(DATA_DIR)$(PATH_SEP)geany$(PATH_SEP)tags$(PATH_SEP)
	@echo ------------------ Installing geany tag done

install-pkgfile:
	$(MKDIR) $(PKGCONFIG_DIR)
	$(CP) $(PKG_CONFIG_FILE) $(DESTDIR)$(PKGCONFIG_DIR)$(PATH_SEP)$(PROJECT_NAME).pc
	@echo ------------------ Installing pkgfile done
