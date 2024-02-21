SRC := $(wildcard $(DEPS_SRC_ROOT)/openssh-$(OPENSSH_SRC_VERSION).tar.gz)
ifeq (,$(SRC))
$(error OPENSSH:$(OPENSSH_SRC_VERSION) SRC not found in $(DEPS_SRC_ROOT))
endif

BUILD_DIR=$(BUILD_ROOT)/$(notdir $(CURDIR))-$(OPENSSH_SRC_VERSION)

OPENSSL_LIB=$(BUILD_ROOT)/install/usr/local/ssl
bindir=/bin
sbindir=/sbin

# fix error
LD=

export CONFIG_USER_SSH_SSH=y
export CONFIG_USER_SSH_SSHD=y
export CONFIG_USER_SSH_SSHKEYGEN=y

all: $(BUILD_DIR)/Makefile
	make -C $(BUILD_DIR) $@

$(BUILD_DIR)/Makefile:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)
	tar -xf $(SRC) -C $(BUILD_DIR) --strip-components 1
	cd $(BUILD_DIR) && \
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(OPENSSL_LIB)/lib && \
	$(BUILD_DIR)/configure --with-ssl-dir=$(OPENSSL_LIB) \
        LDFLAGS="-s"

clean:
	@rm -rf $(BUILD_DIR)

romfs:
	cd $(BUILD_DIR); \
	$(ROOT_DIR)/script/romfs-inst.sh -e CONFIG_USER_SSH_SSH $(bindir)/ssh; \
	$(ROOT_DIR)/script/romfs-inst.sh -e CONFIG_USER_SSH_SSH $(bindir)/scp; \
	$(ROOT_DIR)/script/romfs-inst.sh -e CONFIG_USER_SSH_SSHD $(sbindir)/sshd; \
	$(ROOT_DIR)/script/romfs-inst.sh -e CONFIG_USER_SSH_SSHKEYGEN $(bindir)/ssh-keygen; \
	$(ROOT_DIR)/script/romfs-inst.sh -e CONFIG_USER_SSH_SSHKEYGEN $(bindir)/gen-keys
ifeq ($(CONFIG_USER_SSH_SSH),y)
	-if [ ! -e $(ROMFS_DIR)/usr/admin/.ssh ]; then \
	   mkdir $(ROMFS_DIR)/usr/admin/.ssh; \
	fi
	chmod 700 $(ROMFS_DIR)/usr/admin/.ssh
endif