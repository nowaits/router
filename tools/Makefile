dir += openssl

dir += busybox
dir += bash

dir += pciutils
dir += host-binary
dir += openssh
dir += python
dir += gdb
dir += sudo
dir += tree

all clean romfs:
	@for i in $(dir) ; do \
		make JX=$(JX) $(JX) -C $$i $@ || exit 1 ; \
	done
	$(call show_current_build_time, $@)