SRC := $(wildcard $(DEPS_SRC_ROOT)/openssl-$(OPENSSL_SRC_VERSION).tar.gz)
ifeq (,$(SRC))
$(error OPENSSL SRC:$(OPENSSL_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(OPENSSL_SRC_VERSION)

TARGETS = crypto ssl engines fips apps tools

OPTIONS = \
	--openssldir=/usr/local/ssl shared threads no-camellia	\
	no-capieng no-gmp no-jpake no-krb5 no-mdc2	\
	no-rfc3779 no-seed no-zlib no-zlib-dynamic

# Harmless in $CFLAGS. Userland programs require this for linking.
CFLAGS += -L$(BUILD_ROOT)/install/usr/local/ssl/lib

# Append our own $CFLAGS to $CC so we don't need to override $CFLAG.
CC := $(patsubst $(CROSS_COMPILE)%,%,$(CC)) $(filter-out -shared,$(CFLAGS))

all: $(BUILD_DIR)/Makefile 
	make -C $(BUILD_DIR) depend
	make -C $(BUILD_DIR) all DIRS="$(TARGETS)"
	make -C $(BUILD_DIR) install_sw $(JX) DIRS="$(TARGETS)" \
		INSTALL_PREFIX="$(BUILD_ROOT)/install"

romfs:
	cd $(BUILD_ROOT)/install/usr/local/ssl/lib &&	 \
	for file in libcrypto.so* libssl.so*; \
	do \
		if [ -h "$$file" ];	 \
		then \
			$(ROOT_DIR)/tools/romfs-inst.sh -p 755 -s \
				"`readlink $$file`" \
				"/lib64/$$file"; \
		elif [ -f "$$file" ]; \
		then \
			$(ROOT_DIR)/tools/romfs-inst.sh -p 755 "/lib64/$$file"; \
		fi \
	done; \
 	$(ROOT_DIR)/tools/romfs-inst.sh -p 755 \
	 $(BUILD_ROOT)/install/usr/local/ssl/bin/openssl /usr/local/bin/openssl
	mkdir -p $(ROMFS_DIR)/usr/local/ssl
	touch $(ROMFS_DIR)/usr/local/ssl/openssl.cnf

$(BUILD_DIR)/Makefile :
	[ -d $(BUILD_DIR) ] || (mkdir -p $(BUILD_DIR) && \
		tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1 )
	(cd $(BUILD_DIR) && ./Configure $(OPTIONS) linux-x86_64) ||	\
	! rm -f $@

clean:
	rm -rf $(BUILD_ROOT)/install $(BUILD_DIR)

.PHONY: all clean romfs romfs_lib romfs_usr
