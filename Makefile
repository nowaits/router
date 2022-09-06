export ROOT_DIR  = $(CURDIR)
export IMAGE_DIR = $(ROOT_DIR)/images
export ROMFS_DIR = $(ROOT_DIR)/romfs
export BUILD_ROOT = $(ROOT_DIR)/build

export DEPS_SRC_ROOT = ~/Downloads

export LINUX_SRC_VERSION = 4.11.2
export BASH_SRC_VERSION = 4.4
export BUSYBOX_SRC_VERSION = 1.26.2
export PYTHON_SRC_VERSION = 2.7.6
export PCIUTILS_SRC_VERSION = 3.7.0
export OPENSSL_SRC_VERSION = 1.0.2l
export OPENSSH_SRC_VERSION = 7.5p1
export GDB_VERSION = 12.1
export SUDO_VERSION = 1.9.9
export TREE_SRC_VERSION = 1.8.0

export KERNEL_DEBUG ?= OFF

export BUILD_BEGIN_TIME := $(shell date +%s.%3N)
export show_current_build_time = \
	@time_expr="$$(date +%s.%3N) - $(BUILD_BEGIN_TIME)"; \
	echo -- Now: `bc <<< "$${time_expr}"`s Target: ${1} Done

ifneq ($(KERNEL_DEBUG), OFF)
KERNEL_DEBUG := ON
endif

OS_ID = $(shell grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

DEVTOOLSET = /opt/rh/devtoolset-9/root
ifeq ($(OS_ID),centos)
ifneq ($(wildcard $(DEVTOOLSET)/bin),)
# if has gcc 9, use it!
export PATH := $(DEVTOOLSET)/bin:$(PATH)
endif
else
$(error TODO: OS:$(OS_ID) need to support!)
endif

VENDDIR = $(ROOT_DIR)/vendors/$(CONFIG_VENDOR)/$(CONFIG_PRODUCT)

HOSTCC   = cc
DIRS    = lib user
MAKE = make

JX=-j$(shell nproc --ignore=1)

ARCH          = x86_64
MAKEARCH := make ARCH=$(ARCH)

.PHONY: romfs $(DIRS) image
all: linux $(DIRS) romfs image
	$(call show_current_build_time, $@)

-include $(ROOT_DIR)/deps/linux.mk

romfs: linux-romfs linux-modules-install linux-firmware-install
	@for dir in $(DIRS) ; do [ ! -d $$dir ] || $(MAKEARCH) -C $$dir $@ || exit 1 ; done
	$(call show_current_build_time, $@)

$(DIRS):
	$(MAKEARCH) JX=$(JX) $(JX) -C $@
	$(call show_current_build_time, $@)

.PHONY: clean
clean:
	@for dir in $(DIRS) ; do [ ! -d $$dir ] || $(MAKEARCH) -C $$dir $@ || exit 1 ; done
	$(call show_current_build_time, $@)

deep-clean: clean
	@rm -rf $(IMAGE_DIR) $(ROMFS_DIR) \
		$(ROOT_DIR)/install $(BUILD_ROOT) \
		$(ROOT_DIR)/.linux-*

.PHONY: runkvm
runkvm:
	@tools/kvm-start.sh $(args) --kernel=$(IMAGE_DIR)/bzImage -- $(disk)

gdb:
	@gdb \
    -ex "file $(IMAGE_DIR)/vmlinux" \
    -ex 'set arch i386:x86-64:intel' \
    -ex 'target remote localhost:1234' \
    -ex 'break start_kernel' \
    -ex 'continue' \
    -ex 'disconnect' \
    -ex 'set arch i386:x86-64' \
    -ex 'target remote localhost:1234'