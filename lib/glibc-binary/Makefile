#
# Make link to a binary glibc
#
LIBC_PATH = $(shell gcc $(CPUCFLAGS) $(CFLAGS) -print-file-name=libc.so 2>&1)
LIB_DIR = $(shell echo $(LIBC_PATH) | sed -e 's,/lib32/libc.so,,' -e 's,/lib64/libc.so,,' -e 's,/lib/libc.so,,')

all: clean
	

clean:
	if [ -L build -o -e build ] ; then \
		rm -rf build ; \
	fi

romfs:
	./make_basic_libs-glibc
