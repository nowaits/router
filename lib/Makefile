dir  += glibc-binary
dir  += openssl

all clean romfs:
	@for i in $(dir) ; do \
		make JX=$(JX) $(JX) -C $$i $@ || exit $$? ; \
	done
	$(call show_current_build_time, $@)