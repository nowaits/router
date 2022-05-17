#!/bin/sh

# Install a lib that comes from toolchain in romfs and in
# ROOT_DIR/debug. If the specified name matches libxxx.so the
# script will also install the associated libxxx.so.y
#
# Arg 1 : name of the lib.
# Arg 2 : install path ("lib", "lib32" or "lib64")
# Arg 3 : path to libs -optional
# Arg 4 : -u [unstripped] -optional
#
# The ROOT_DIR variable must be defined.
#
# Example:
#   install_lib.sh libc.so.6 /path/to/romfs

ROMFS_LIB_DIR=${ROMFS_DIR}/$2
UNSTRIPPED=N

[ -d ${ROMFS_LIB_DIR} ] || mkdir -p ${ROMFS_LIB_DIR}

if [ ! -z $4 ];then
    FILE_LINK=$3/$1
    UNSTRIPPED=Y
elif [ -z $3 ];then
    FILE_LINK=`gcc -print-file-name=$1`
elif [ $3 = "-u" ];then
    FILE_LINK=`gcc -print-file-name=$1`
    UNSTRIPPED=Y
else
    FILE_LINK=$3/$1
fi

if [ -h $FILE_LINK ]; then
    FILE=`stat -c %N $FILE_LINK | sed 's,^.*-> .\(.*\).$,\1,'`
    FILE=`basename $FILE`

    # check if the link name is diffrent from the file name
    if [ "`basename $FILE_LINK`" != "$FILE" ]; then
	    ln -snf $FILE ${ROMFS_LIB_DIR}/`basename $FILE_LINK`
    fi
else
    FILE=`basename $FILE_LINK`
    if [ -e $FILE_LINK ] && [ ! -z "readelf" ]; then
	SONAME=$(readelf -d $FILE_LINK | grep SONAME | sed 's/.*[[]\(.*\)[]].*/\1/g')
	if [ "$SONAME" != "$FILE" ];then
	    ln -snf $FILE ${ROMFS_LIB_DIR}/$SONAME
	fi
    fi
fi

if [ -f `dirname $FILE_LINK`/$FILE ]; then
    echo installing $FILE
    if [ $UNSTRIPPED = "Y" ];then
	cp `dirname $FILE_LINK`/$FILE ${ROMFS_LIB_DIR}/$FILE
    else
	strip -o ${ROMFS_LIB_DIR}/$FILE `dirname $FILE_LINK`/$FILE
    fi
    chmod 755 ${ROMFS_LIB_DIR}/$FILE
else
    echo $FILE not found
fi
