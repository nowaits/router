
BINARY_LIST += kexec
BINARY_LIST += lscpu
BINARY_LIST += ip
BINARY_LIST += tcpdump
BINARY_LIST += ldd

all clean:

romfs:
	@for i in $(BINARY_LIST) ; do \
		$(CURDIR)/install.sh $$i; \
	done