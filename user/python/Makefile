SRC := $(wildcard $(DEPS_SRC_ROOT)/Python-$(PYTHON_SRC_VERSION).tar.xz)
ifeq (,$(SRC))
$(error PYTHON SRC:$(PYTHON_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(PYTHON_SRC_VERSION)

B_HOST := $(BUILD_DIR)/host
B_TARGET := $(BUILD_DIR)/target

# configure options for the target build
CONFIGURE_OPTS := --host=$(shell gcc -dumpmachine)
CONFIGURE_OPTS += --build=$(shell gcc -dumpmachine)
CONFIGURE_OPTS += --sysconfdir=/etc
CONFIGURE_OPTS += --prefix=/usr/local
CONFIGURE_OPTS += --libdir=/lib64
CONFIGURE_OPTS += --enable-ipv6
CONFIGURE_OPTS += --enable-unicode=ucs4
CONFIGURE_OPTS += buggygetaddrinfo=no
CONFIGURE_OPTS += ac_cv_file__dev_ptmx=no
CONFIGURE_OPTS += ac_cv_file__dev_ptc=no
CONFIGURE_OPTS += ac_cv_have_long_long_format=yes
CONFIGURE_OPTS += _PYTHON_HOST_BASE=$(B_HOST)
CONFIGURE_OPTS += _PYTHON_PROJECT_BASE=$(B_TARGET)

# these are subdirectories of "Lib" that will be installed by make install
PY_LIBSUBDIRS :=	site-packages multiprocessing encodings compiler json logging \
			importlib ctypes ctypes/macholib lib-old \
			xml xml/etree xml/sax xml/dom xml/parsers \
			email email/mime email/test
# skip building these unneeded C extensions to save time
DISABLED_PY_MODULES :=	audioop _curses _curses_panel _sqlite3 _elementtree \
			_tkinter _hotshot _ctypes_test _csv _lsprof \
			_multibytecodec _codecs_kr _codecs_jp _codecs_cn \
			_codecs_tw _codecs_hk _codecs_iso2022 \
			dbm gdbm bsddb nis linuxaudiodev \
			ossaudiodev imageop

# common variables to all make and configure calls
COMMON_ARGS := DISABLED_PY_MODULES="$(DISABLED_PY_MODULES)"
COMMON_ARGS += PY_LIBSUBDIRS="$(PY_LIBSUBDIRS)"
# Arguments for host compilation
HOST_ARGS   := $(COMMON_ARGS)
HOST_ARGS   += CC=gcc AR=ar CXX=g++ LD=ld ranlib=ranlib
HOST_ARGS   += CFLAGS= LDFLAGS="-s"
# Arguments for target compilation
TARGET_ARGS := $(COMMON_ARGS)
TARGET_ARGS += DESTDIR=$(ROMFS_DIR)
TARGET_ARGS += CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS) -s"
TARGET_ARGS += PGEN_FOR_BUILD=$(B_HOST)/Parser/pgen

.PHONY: all
all: $(B_TARGET)/python

.PHONY: romfs
romfs: $(ROMFS_DIR)/usr/local/bin/python

$(ROMFS_DIR)/usr/local/bin/python: $(B_TARGET)/python
	$(MAKE) $(JX) -C $(B_TARGET) $(TARGET_ARGS) install
	sh $(CURDIR)/extension/install.sh $(ROMFS_DIR)/usr/local/lib/python2.7/site-packages
	rm -rf $(ROMFS_DIR)/usr/local/bin/pydoc
	rm -rf $(ROMFS_DIR)/usr/local/bin/idle
	rm -rf $(ROMFS_DIR)/usr/local/bin/2to3
	rm -rf $(ROMFS_DIR)/usr/local/include/python2.7
	rm -rf $(ROMFS_DIR)/usr/local/bin/smtpd.py
	rm -rf $(ROMFS_DIR)/lib64/libpython*.a
	rm -rf $(ROMFS_DIR)/lib64/python2.7/config

# compile the "target" interpreter + C extensions
$(B_TARGET)/python: $(B_TARGET)/Makefile
	$(MAKE) $(JX) -C $(B_TARGET) $(TARGET_ARGS)

# run configure for the "target" interpreter
$(B_TARGET)/Makefile: $(B_HOST)/python $(B_HOST)/Parser/pgen | $(B_TARGET)
	cd $(B_TARGET); ./configure $(TARGET_ARGS) $(CONFIGURE_OPTS)

# compile the "host" interpreter + C extensions
$(B_HOST)/python $(B_HOST)/Parser/pgen: $(B_HOST)/Makefile
	-$(MAKE) $(JX) -C $(B_HOST) $(HOST_ARGS)

# run configure for the "host" interpreter
$(B_HOST)/Makefile: | $(B_HOST)
	cd $(B_HOST); ./configure $(HOST_ARGS)

# untar sources in the specified subdir and apply necessary patches
$(B_HOST) $(B_TARGET):
	rm -rf $@
	mkdir -p $@
	tar -xJf $(SRC) --strip-components=1 -C $@
	for p in $(PATCHES); do patch -p1 -d $@ < $$p; done

.PHONY: clean
clean:
	rm -rf $(B_HOST) $(B_TARGET)
	rm -rf $(ROMFS_DIR)/usr/local/bin/python*
	rm -rf $(ROMFS_DIR)/usr/local/lib/python*
	rm -rf $(ROMFS_DIR)/lib64/python*