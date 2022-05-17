SRC := $(wildcard $(DEPS_SRC_ROOT)/busybox-$(BUSYBOX_SRC_VERSION).tar.bz2)
ifeq (,$(SRC))
$(error BUSYBOX SRC:$(BUSYBOX_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(BUSYBOX_SRC_VERSION)

all: $(BUILD_DIR)/.config
	@$(MAKE) -C $(BUILD_DIR) $(JX)

$(BUILD_DIR)/.config:
	@mkdir -p $(BUILD_DIR)
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1
	cp config-$(BUSYBOX_SRC_VERSION) $@

romfs: $(BUILD_DIR)/.config
	@$(MAKE) -C $(BUILD_DIR) install CONFIG_PREFIX=$(ROMFS_DIR)

clean:
	@[ ! -d $(BUILD_DIR) ] || $(MAKE) -C $(BUILD_DIR) uninstall CONFIG_PREFIX=$(ROMFS_DIR)
	@[ ! -d $(BUILD_DIR) ] || $(MAKE) -C $(BUILD_DIR) clean
