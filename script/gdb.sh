#!/bin/bash
set -e

ROOT_DIR=`realpath $(dirname $0)`
cd $ROOT_DIR

. $ROOT_DIR/env.ini

usage() {
    cat <<EOF
Usage: ${0##*/} OPTIONS

OPTIONS:
  -p/--port         gdb port
  -l/--linux        vmlinux path
  -h/--help         help
EOF
    exit 1
}

# args
PREFIX=ts
GDB=
PORT="1234"
LINUX=

for i in "$@"
do
case $i in
    -p=*|--port=*)
        PORT="${i#*=}"
    shift
    ;;
    -l=*|--linux=*)
        LINUX="${i#*=}"
    shift
    ;;
    *)
        echo -e "****** Unsupport option:${RED}[$i]${RES} ******"
        usage
    ;;
esac
done

if [ -z $LINUX ]; then
    usage
fi

# args
LINUX_ROOT=`dirname $LINUX`

GDB_CMDS=/tmp/gdb-$HASH_ID
gdb_tpl $GDB_CMDS /tmp/${PREFIX}-gdb-debug.log

#echo "set arch i386:x86-64:intel" >> $GDB_CMDS
#echo "set arch i386:x86-64" >> $GDB_CMDS
echo "target remote localhost:$PORT" >> $GDB_CMDS

if [ -f $ROOT_DIR/.gdb_cache ]; then
    cat $ROOT_DIR/.gdb_cache >> $GDB_CMDS;
else
   echo "c" >> $GDB_CMDS;
fi

gdb --quiet -x $GDB_CMDS -iex "set auto-load safe-path /" $LINUX_ROOT/vmlinux