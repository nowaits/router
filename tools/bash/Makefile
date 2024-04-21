SRC := $(wildcard $(DEPS_SRC_ROOT)/bash-$(BASH_SRC_VERSION).tar.gz)
ifeq (,$(SRC))
$(error BASH SRC:$(BASH_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(BASH_SRC_VERSION)

$(BUILD_DIR)/Makefile:
	@mkdir -p $(BUILD_DIR); \
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1
	cd $(BUILD_DIR) && ./configure --prefix=/ \
		CFLAGS="-O3" \
        LDFLAGS="-s"

all:  $(BUILD_DIR)/Makefile
	@make -C $(BUILD_DIR) $@ && strip $(BUILD_DIR)/bash

romfs:
	[ -f $(BUILD_DIR)/bash ] && cp $(BUILD_DIR)/bash $(ROMFS_DIR)/bin
	[ -d /lib/terminfo ] && cp -r /lib/terminfo $(ROMFS_DIR)/lib/

clean:
	@rm -rf $(BUILD_DIR)