SRC := $(wildcard $(DEPS_SRC_ROOT)/sudo-$(SUDO_VERSION).tar.gz)
ifeq (,$(SRC))
$(error GDB SRC:$(SUDO_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(SUDO_VERSION)

OPENSSL_LIB=$(BUILD_ROOT)/install/usr/local/ssl

all: $(BUILD_DIR)/Makefile
	@$(MAKE) -C $(BUILD_DIR) $(JX)

$(BUILD_DIR)/Makefile:
	@mkdir -p $(BUILD_DIR) && \
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1 && \
	cd $(BUILD_DIR) && \
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(OPENSSL_LIB)/lib && \
	./configure --prefix=$(ROMFS_DIR) \
		--enable-shared=no \
		--enable-static=no \
		--includedir=$(BUILD_DIR)/_tmp \
        CFLAGS="-I$(OPENSSL_LIB)/include" \
        LDFLAGS="-L$(OPENSSL_LIB)/lib -s"

romfs: $(BUILD_DIR)/Makefile
	@$(MAKE) -C $(BUILD_DIR) \
		LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(OPENSSL_LIB)/lib \
		install

clean:
	@rm -rf $(BUILD_DIR)