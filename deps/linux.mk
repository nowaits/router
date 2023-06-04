ifndef ROOT_DIR
$(error ROOT_DIR not defined)
endif

ifndef LINUX_SRC_VERSION
$(error LINUX_SRC_VERSION not defined)
endif

ifndef LINUX_OUTPUT
$(error LINUX_OUTPUT not defined)
endif

LINUX_SRC := $(wildcard $(DEPS_SRC_ROOT)/linux-$(LINUX_SRC_VERSION).tar.*z)
ifeq (,$(LINUX_SRC))
$(error LINUX SRC:$(LINUX_SRC_VERSION) not found in $(DEPS_SRC_ROOT))
endif

MACHINE       = x86_64
ARCH          = x86_64

MAKEARCH_KERNEL := make ARCH=$(ARCH) O=$(LINUX_OUTPUT)

LINUX_DIR := $(ROOT_DIR)/.linux-$(LINUX_SRC_VERSION)

DEPS_DIR := $(ROOT_DIR)/deps/linux

ROMFS_DIRS = \
	bin \
	dev dev/shm \
	etc etc/scripts \
	lib lib/modules \
	proc \
	sys \
	root \
	sbin \
	usr \
		usr/bin usr/sbin usr/share \
		usr/local usr/local/bin usr/local/sbin usr/local/etc \
		usr/admin/.ssh usr/admin/cli/commands \
		usr/admin/cli/keypub \
	var \
		var/lock var/log var/empty var/tmp/log var/run

ifneq ($(KERNEL_DEBUG), OFF)
KERNEL_CONFIG = $(DEPS_DIR)/$(ARCH)/config/linux-generic-$(LINUX_SRC_VERSION)-debug
else
KERNEL_CONFIG = $(DEPS_DIR)/$(ARCH)/config/linux-generic-$(LINUX_SRC_VERSION)
endif

ifeq ($(wildcard $(KERNEL_CONFIG)),)
$(error LINUX Build config:$(KERNEL_CONFIG) not find!)
endif

$(LINUX_DIR):
	@echo "linux source extracting: $(notdir ${LINUX_SRC}) => $(notdir $@)"
	@mkdir -p $@ && \
	tar -xf ${LINUX_SRC} -C $@ --strip-components=1 && \
	if [ -d $(DEPS_DIR)/patchs/$(LINUX_SRC_VERSION) ]; then \
		git apply --directory=$(LINUX_DIR) \
			--unsafe-paths $(DEPS_DIR)/patchs/$(LINUX_SRC_VERSION)/*.patch; \
	fi
	$(call show_current_build_time, $@)

linux-src: $(LINUX_DIR)

$(LINUX_OUTPUT)/.config: $(LINUX_DIR)
	@$(MAKEARCH_KERNEL) -C $(LINUX_DIR) O=$(LINUX_OUTPUT) mrproper && \
	cp $(KERNEL_CONFIG) $(LINUX_OUTPUT)/.config && \
	$(MAKEARCH_KERNEL) -C $(LINUX_DIR) headers_install INSTALL_HDR_PATH=$(LINUX_DIR)/usr
	$(call show_current_build_time, $@)

.PHONY: linux
linux: $(LINUX_OUTPUT)/.config
	@if [ "$(KEEP_CPIO_DESC)" != "1" ]; then \
		rm -f $(LINUX_OUTPUT)/romfs_cpio.desc ; \
		touch $(LINUX_OUTPUT)/romfs_cpio.desc ; \
	fi && \
	$(MAKEARCH_KERNEL) -C $(LINUX_DIR) all bzImage $(JX)
	$(call show_current_build_time, $@)

linux-modules-install:
	. $(LINUX_OUTPUT)/.config; if [ "$$CONFIG_MODULES" = "y" ]; then \
		[ -d $(ROMFS_DIR)/lib/modules ] || mkdir -p $(ROMFS_DIR)/lib/modules; \
		$(MAKEARCH_KERNEL) -C $(LINUX_DIR) INSTALL_MOD_PATH=$(ROMFS_DIR) DEPMOD=/bin/true modules_install; \
		rm -f $(ROMFS_DIR)/lib/modules/*/build $(ROMFS_DIR)/lib/modules/*/source; \
	fi
	$(call show_current_build_time, $@)

linux-firmware-install:
	@if [ -d "$(LINUX_DIR)/firmware" ]; then \
	   $(MAKEARCH_KERNEL) -C $(LINUX_DIR) INSTALL_MOD_PATH=$(ROMFS_DIR); \
	fi
	$(call show_current_build_time, $@)

.PHONY: linux_xconfig linux_menuconfig linux_config
linux-xconfig:
	$(MAKEARCH_KERNEL) -C $(LINUX_DIR) xconfig
	$(call show_current_build_time, $@)
linux-menuconfig:
	$(MAKEARCH_KERNEL) -C $(LINUX_DIR) menuconfig
	$(call show_current_build_time, $@)
linux-config:
	$(MAKEARCH_KERNEL) -C $(LINUX_DIR) config
	$(call show_current_build_time, $@)

linux-romfs:
	@[ -d $(ROMFS_DIR) ] || mkdir -p $(ROMFS_DIR)
	@for i in $(ROMFS_DIRS); do \
		[ -d $(ROMFS_DIR)/$$i ] || mkdir -p $(ROMFS_DIR)/$$i; \
	done
	@# install : common romfs, common-arch romfs and arch romfs
	$(ROOT_DIR)/tools/romfs-inst.sh $(DEPS_DIR)/$(ARCH)/filesystem /; \
	if [ -f ~/.ssh/id_rsa ]; then \
		install ~/.ssh/id_rsa* -m 600 $(ROMFS_DIR)/etc/ssh; \
	fi
	$(call show_current_build_time, $@)

copy-image:
	@echo "Generating image"; \
	cp $(LINUX_OUTPUT)/arch/$(ARCH)/boot/bzImage $(IMAGE_DIR)/; \
	cp $(LINUX_OUTPUT)/vmlinux $(IMAGE_DIR)/;
	$(call show_current_build_time, $@)
	
prepare-image: 
	[ -d $(IMAGE_DIR) ] || mkdir -p $(IMAGE_DIR)
	@# Create links in /var/tmp, /usr/admin, ... from /etc
	sh $(DEPS_DIR)/mklink.sh $(ROMFS_DIR)
	$(call show_current_build_time, $@)

linux-image: prepare-image copy-image
	@# do the packaging
	env KERNEL_DIR=$(LINUX_OUTPUT) \
		$(DEPS_DIR)/$(ARCH)/packaging/packaging.sh \
		$(IMAGE_DIR)/bzImage $(DEPS_DIR)/$(ARCH)/packaging $(ROMFS_DIR) $(LINUX_OUTPUT)
	$(call show_current_build_time, $@)

.PHONY: image
image: linux-image

linux-clean:
	@rm -rf $(LINUX_OUTPUT)