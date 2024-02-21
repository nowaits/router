SRC := $(wildcard $(DEPS_SRC_ROOT)/pciutils-$(PCIUTILS_SRC_VERSION).tar.gz)
ifeq (,$(SRC))
$(error PCIUTILS SRC:$(PCIUTILS_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(PCIUTILS_SRC_VERSION)

all: $(BUILD_DIR)/Makefile
	@make -C $(BUILD_DIR) $@

clean:
	@rm -rf $(BUILD_DIR)

$(BUILD_DIR)/Makefile:
	@mkdir -p $(BUILD_DIR)
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1

romfs:
	@cd $(BUILD_DIR); \
	$(ROOT_DIR)/script/romfs-inst.sh /usr/bin/lspci