#!/bin/sh
#
# Copyright 2006 6WIND, All rights reserved
#   Vincent.Jardin@6wind.com
# $Id: romfs2cpio_list.sh,v 1.2 2006-09-19 15:04:25 andriot Exp $
#
# Generate a descriptor of cpio file from:
#   the romfs (arg1) + the dev_all.txt (arg2)
# this descriptor can be used be gen_cpio of Linux Kernel 2.6
ROMFS_DIR=$1
DEVALL=$2

usage()
{
  echo "$0 romfs/ path/dev_all.txt" >&2
  exit 1
}

# dir <name> <mode> <uid> <gid>
# we assume uid, gid = 0, 0
# arg1 = name of the directory to be added
process_dir()
{
  MODE=`stat -c %a ${ROMFS_DIR}/$1`
  echo "dir /$1 ${MODE} 0 0"
}

# slink <name> <target> <mode> <uid> <gid>
# we assume uid, gid = 0, 0
# arg1 = name of the symlink to be added
process_symlink()
{
  MODE=`stat -c %a ${ROMFS_DIR}/$1`
  TARGET=`stat -c %N ${ROMFS_DIR}/$1  | cut -f 3 -d ' ' |  sed 's,^.,,' | sed 's,.$,,'`
  echo "slink /$1 ${TARGET} ${MODE} 0 0"
}

# file <name> <location> <mode> <uid> <gid>
# we assume uid, gid = 0, 0
# arg1 = name of the file to be added
process_regfile()
{
  MODE=`stat -c %a ${ROMFS_DIR}/$1`
  echo "file /$1 ${ROMFS_DIR}/$1 ${MODE} 0 0"
}

is_symlink()
{
  TYPE=`stat -c %f $1`
  if [ "${TYPE}" != "a1ff" ] ; then
    return 1
  fi
  return 0
}

if [ ! -d ${ROMFS_DIR} ] ; then
  usage
  exit 1
fi

if [ ! -f ${DEVALL} ] ; then
  usage
  exit 1
fi

echo "# Copyright 2006 6WIND"
echo "# generated with"
echo "#    $0 $1 $2"

# 1/ process romfs/
# list of files without the . characters
LIST_FILE=`cd ${ROMFS_DIR} && find . | cut -c 3-`

for i in ${LIST_FILE} ; do
  # -L cannot be used because the symlink exist, but not the file
  if is_symlink ${ROMFS_DIR}/$i ; then
    process_symlink $i
    continue
  fi
  if [ -d ${ROMFS_DIR}/$i ] ; then
    process_dir $i
    continue
  fi
  if [ -f ${ROMFS_DIR}/$i ] ; then
    process_regfile $i
    continue
  fi
  if [ -b ${ROMFS_DIR}/$i ] ; then
    # ignore block files TBD??
    continue
  fi
  if [ -c ${ROMFS_DIR}/$i ] ; then
    # ignore char files TBD??
    continue
  fi
  echo "[WARNING] Type of $i is unknown" >&2
  echo "[WARNING] Cannot put file $i in ramfs" >&2
  echo "[WARNING] FILE SYSTEM WILL BE INCOMPLETE" >&21
done

# 2/ process dev_all.txt
cat ${DEVALL} | awk '
# Parse dev_all.txt files and format a description of char/block devices
# for the initramfs cpio file.

# nod <name> <mode> <uid> <gid> <dev_type> <maj> <min>
# eg.: nod /dev/console 0600 0 0 c 5 1
function process_nod(name, mode, major, minor, perm, uid, gid) {
   match(name, "[a-zA-Z0-9]+$");
   fullname = "."substr(name, 0, length(name)-RLENGTH) "@" substr(name,RSTART) "," mode "," major "," minor;
   printf "nod %s %s %d %d %s %d %d\n", name, perm, uid, gid, mode, major, minor ;
}


# This is the main function of the script. 
# First only non-commented lines are matched.
# Then each field is stored into its own variable
$1 ~ /^[^#]/ {
name = $1;
mode = $2;
perm = $3;
uid = $4;
gid = $5;
major = $6;
minor = $7;
start = $8;
inc = $9;
count = $10;

if (mode == "d") {
   # dir <name> <mode> <uid> <gid>
   printf "dir %s %s %d %d \n", name, perm, uid, gid;
} else if ((mode == "c") || (mode == "b")) {
   # If the file is a char device or a block device, then
   #   - If there is a "count" shortcut, generate each name separately and call create_file().
   #   - Else just forward the arguments to create_file().
   if (count == "-")
      process_nod(name, mode, major, minor, perm, uid, gid)
   else {
      for (i=start; i < count; i+=inc)
         process_nod(name""i, mode, major, minor+i-1, perm, uid, gid);
   }
}

}
'

