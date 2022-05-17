#!/bin/sh
set -e

echo "Installing file: $1"

file=`which $1 2>&1`

if [ $? -ne 0 ] ; then exit 0 ; fi

rm -rf ${ROMFS_DIR}/$file

mkdir -p ${ROMFS_DIR}`dirname $file`
cp $file ${ROMFS_DIR}`dirname $file`