export ROOT_DIR  = $(CURDIR)
export IMAGE_DIR = $(ROOT_DIR)/images
export ROMFS_DIR = $(ROOT_DIR)/romfs
export BUILD_ROOT = $(ROOT_DIR)/build
export LINUX_OUTPUT = $(BUILD_ROOT)/linux

export DEPS_SRC_ROOT = ~/Downloads

export LINUX_SRC_VERSION = 4.11.2
export BASH_SRC_VERSION = 4.4
export BUSYBOX_SRC_VERSION = 1.35.0
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
	@time_used=`echo $$(date +%s.%3N) - $(BUILD_BEGIN_TIME)|bc`; \
	echo - Now: $${time_used}s Target: ${1} Done

find_lib_path =	\
	`path=$$(gcc --print-file-name=$(1)); \
	if [ -f $${path} ]; then echo $${path}; fi`

ifneq ($(KERNEL_DEBUG), OFF)
KERNEL_DEBUG := ON
endif

BUILD_ONLY_KERNEL := OFF

ifneq ($(shell uname),Darwin)
OS_ID = $(shell grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID= $(shell grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
else
$(error TODO: OS:Darwin need to support!)
endif

ifeq ($(OS_ID)-$(OS_VERSION_ID),centos-7)
DEVTOOLSET = /opt/rh/devtoolset-9/root
ifneq ($(wildcard $(DEVTOOLSET)/bin),)
# if has gcc 9, use it!
export PATH := $(DEVTOOLSET)/bin:$(PATH)
endif
else ifeq ($(OS_ID)-$(OS_VERSION_ID),ubuntu-20.04)
else ifeq ($(OS_ID)-$(OS_VERSION_ID),ubuntu-22.04)
else
$(error TODO: OS:$(OS_ID)-$(OS_VERSION_ID) need to support!)
endif

VENDDIR = $(ROOT_DIR)/vendors/$(CONFIG_VENDOR)/$(CONFIG_PRODUCT)

HOSTCC   = cc
DIRS    = tools
MAKE = make

JX=-j$(shell nproc --ignore=1)

ARCH          = x86_64
MAKEARCH := make ARCH=$(ARCH)

#
# Busybox CONFIG_USE_BB_PWD_GRP=y
#
BUSYBOXY_NSS_DEPS= \
	libnss_compat.so.2 \
	libnss_dns.so.2 \
	libnss_files.so.2 \
	libnss_hesiod.so.2 \
	libnss_nisplus.so.2 \
	libnss_nis.so.2 \

LIB_DEPS_LIST= \
	$(BUSYBOXY_NSS_DEPS)


.PHONY: romfs $(DIRS) image
all: linux $(DIRS) romfs romfs-host-deps image
	$(call show_current_build_time, $@)

-include $(ROOT_DIR)/deps/linux.mk

romfs: linux-romfs linux-modules-install linux-firmware-install
ifeq ($(BUILD_ONLY_KERNEL), OFF)
	@for dir in $(DIRS) ; do [ ! -d $$dir ] || $(MAKEARCH) -C $$dir $@ || exit 1 ; done
endif
	$(call show_current_build_time, $@)

$(DIRS):
ifeq ($(BUILD_ONLY_KERNEL), OFF)
	$(MAKEARCH) JX=$(JX) $(JX) -C $@
	$(call show_current_build_time, $@)
endif

romfs-host-deps:
	@for f in $(LIB_DEPS_LIST); do \
		lib=$(call find_lib_path,$$f); \
		libs="$$lib $$libs"; \
	done; \
	fs="`python $(CURDIR)/script/romfs-host-deps.py $(ROMFS_DIR) \"$$libs\"`"; \
	for f in $$fs; do \
		dst=$(ROMFS_DIR)/$$f; \
		mkdir -p `dirname $$dst`; \
		echo "installing... $$f => $$dst"; \
		install $$f $$dst; \
	done
	$(call show_current_build_time, $@)

.PHONY: clean
clean:
	@for dir in $(DIRS) ; do [ ! -d $$dir ] || $(MAKEARCH) -C $$dir $@ || exit 1 ; done
	$(call show_current_build_time, $@)

deep-clean: clean linux-clean
	@rm -rf $(IMAGE_DIR) $(ROMFS_DIR) \
		$(ROOT_DIR)/install $(BUILD_ROOT); \
	[ -d $(ROOT_DIR)/.linux-*/.git ] || rm -rf $(ROOT_DIR)/.linux-*
	$(call show_current_build_time, $@)
		

.PHONY: runkvm
runkvm:
	@script/kvm-start.sh $(args) --kernel=$(IMAGE_DIR)/bzImage -- $(disk)

gdb:
	@script/gdb.sh \
		--port=1234 \
		--linux=$(LINUX_OUTPUT)/vmlinux