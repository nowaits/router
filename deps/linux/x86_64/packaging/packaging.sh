#!/bin/bash
set -e

#
# Copyright (c) 2004-2005 6WIND
#
#--- packaging kernel + ramdisk + script + common information + script.tgz length + MAGIC
#-for GRUB on x86
#--- Start Date : Mar 11, 2004
#--- Writer     : Trung Tran

#********************************************************************************************
# Update file format:
# *******************
#                                            216 bytes          20 bytes       20 bytes
#    +-------------------+-------------+------------------+--------------------+---------+
#    | kernel + ramdisk  | scripts.tgz |common information| scripts.tgz length |  MAGIC  |
#    +-------------------+-------------+------------------+--------------------+---------+
#                                       <----- 256 bytes. To dump them: tail -c 256 ----->
#
#********************************************************************************************
KERNEL_FILE=$1
SCRIPT_PATH=$2
ROMFS_DIR=$3
OUTPUT_DIR=$4

CURDIR=`realpath $(dirname $0)`

. ${CURDIR}/libconfig

BUILD_OVA=1

#--- usage
usage ()
{
	echo error: $1
	echo usage: $0 \<KERNEL_FILE\> \<SCRIPT_PATH\> \<ROMFS_DIR\> \<OUTPUT_DIR\>
	exit 1
}


#--- Check parameter
if [ ! $# -eq 4 ]
then
	usage "invalid parameter numbers"
fi

[ -d ${KERNEL_DIR} ] || exit 1

DIR=$(dirname $0)
KERNEL_CONFIG_FILE=${KERNEL_DIR}/.config
ROMFS_DESC=romfs_cpio.desc
BLOCK_SIZE=1024

# /init -> /sbin/init
[ ! -e ${ROMFS_DIR}/init ] || rm ${ROMFS_DIR}/init
ln -s /sbin/init ${ROMFS_DIR}/init

#--- kernel with initramfs
# set the initramfs options for kernel
set_val_in_config CONFIG_INITRAMFS_SOURCE ${KERNEL_CONFIG_FILE} \"${ROMFS_DESC}\"
set_val_in_config CONFIG_INITRAMFS_ROOT_UID ${KERNEL_CONFIG_FILE} 0
set_val_in_config CONFIG_INITRAMFS_ROOT_GID ${KERNEL_CONFIG_FILE} 0
set_val_in_config CONFIG_INITRAMFS_COMPRESSION_NONE ${KERNEL_CONFIG_FILE} n
set_val_in_config CONFIG_INITRAMFS_COMPRESSION_GZIP ${KERNEL_CONFIG_FILE} y

echo "Building romfs cpio description"
${ROOT_DIR}/tools/initramfs/romfs2cpio_list.sh ${ROMFS_DIR} ${DIR}/dev_all.txt > ${KERNEL_DIR}/${ROMFS_DESC}
echo "Building linux with new initramfs"

# make sure to rebuild it
rm -f ${KERNEL_DIR}/usr/initramfs_data.cpio.gz
rm -f ${KERNEL_DIR}/usr/initramfs_data.gz.o
make -C ${ROOT_DIR} linux KEEP_CPIO_DESC=1 
# use the recompiled image
make -C ${ROOT_DIR} copy-image