SRC := $(wildcard $(DEPS_SRC_ROOT)/tree-$(TREE_SRC_VERSION).tgz)
ifeq (,$(SRC))
$(error Tree SRC:$(TREE_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(TREE_SRC_VERSION)

all: $(BUILD_DIR)/Makefile
	@make -C $(BUILD_DIR) $@

clean:
	@rm -rf $(BUILD_DIR)

$(BUILD_DIR)/Makefile:
	@mkdir -p $(BUILD_DIR)
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1

romfs:
	@cd $(BUILD_DIR); \
	$(ROOT_DIR)/tools/romfs-inst.sh /usr/bin/tree