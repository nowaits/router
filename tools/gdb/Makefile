SRC := $(wildcard $(DEPS_SRC_ROOT)/gdb-$(GDB_VERSION).tar.xz)
ifeq (,$(SRC))
$(error GDB SRC:$(GDB_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(GDB_VERSION)

all: $(BUILD_DIR)/Makefile
	@$(MAKE) -C $(BUILD_DIR) $(JX)

$(BUILD_DIR)/Makefile:
	@mkdir -p $(BUILD_DIR) && \
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1 && \
	cd $(BUILD_DIR) && ./configure \
		--prefix=$(ROMFS_DIR) \
		--includedir=$(BUILD_DIR)/_/include \
		--libdir=$(BUILD_DIR)/_/lib \
		--enable-inprocess-agent=no \
        LDFLAGS="-s"

romfs: $(BUILD_DIR)/Makefile
	@$(MAKE) -C $(BUILD_DIR) install

clean:
	@rm -rf $(BUILD_DIR)
