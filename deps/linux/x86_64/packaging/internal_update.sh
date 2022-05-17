#!/bin/sh
#--- Internal update script for grub on x86


	
# activate DEBUG trace
VERBOSE=0

report ()
{
    if [ $VERBOSE -eq 1 ] ; then
	echo $1
    fi
}

KERNEL_FILE=$1
report "KERNEL_FILE=${KERNEL_FILE}"
VERSION=$2
RAMDISK_OFFSET=$3

# compatibility with old mount point
if mount | grep -q '/var/tmp/mnt2'; then 
    MNT_PATH=/var/tmp/mnt2
else
    MNT_PATH=/var/tmp/mnt
fi

GRUB_CONFIG=${MNT_PATH}/boot/grub/menu.lst
OLDGRUB_CONFIG=${MNT_PATH}/boot/grub/menu.lst.old

USRADMIN_DEV=`mount | grep /usr/admin | cut -d ' ' -f 1-1`
IMAGE_DEV=`echo $USRADMIN_DEV | tr "1-9" "0-8"`


#--- Get infos for running kernel (rollback)
if grep "current_image=" /proc/cmdline > /dev/null ; then
    CURRENT_IMAGE_NAME=`sed 's,^.*current_image=\([^\ ]*\).*$,\1,' /proc/cmdline`
else 
    if [ -f /etc/bootname ]; then
	CURRENT_IMAGE_NAME=`cat /etc/bootname`
    else
	CURRENT_IMAGE_NAME=""
    fi
fi

# Get boot command-line and strip generated part.
read -r SAVED_CMDLINE < /proc/cmdline ||
report "Warning: cannot read boot command-line."
SAVED_CMDLINE="${SAVED_CMDLINE#* current_image=* }"

# If console is part of that command-line, do not override it.
CONSOLE='console=ttyS0,115200'
echo "$SAVED_CMDLINE" |
grep -q '\<console\>=' &&
CONSOLE=''

IS_INITRAMFS=0

if [ "x$CURRENT_IMAGE_NAME" != "x" ]; then 
    CURRENT_RAMDISKSIZE=`cat /proc/cmdline | sed -n 's/\(^.* \|^\)ramdisk_start=\([0-9][0-9]*\).*$/\2/p'`

    #--- Check if current kernel uses initramfs
    if [ -z $CURRENT_RAMDISKSIZE ]; then
	IS_INITRAMFS=1
    fi
    report "Old kernel is : $CURRENT_IMAGE_NAME, ramdisk_start : $CURRENT_RAMDISKSIZE"
else
    report "No rollback"
fi

#--- Check space left
SPACELEFT=`df -k | grep '^'$IMAGE_DEV | awk '{ print $4 }'`
IMAGESIZE=`du -k $KERNEL_FILE | awk '{ print $1 }'`

# don't check space left if image is already on image_dev
if df -k $KERNEL_FILE | grep -q $IMAGE_DEV; then
    report "Image already on correct device"
else
    if [ "$CURRENT_IMAGE_NAME" != "" -a -f "${MNT_PATH}/boot/$CURRENT_IMAGE_NAME" ]; then
	OLDIMAGESIZE=`du -k ${MNT_PATH}/boot/$CURRENT_IMAGE_NAME | awk '{ print $1 }'`
    else
	OLDIMAGESIZE=0
    fi
    
    report SPACELEFT=$SPACELEFT
    report IMAGESIZE=$IMAGESIZE
    report OLDIMAGESIZE=$OLDIMAGESIZE
    
    if [ $SPACELEFT -lt $IMAGESIZE ]; then
	if [ $(($SPACELEFT+$OLDIMAGESIZE)) -lt $IMAGESIZE ]; then
	    echo "ERROR: Not enough space on device"
	    rm -f $KERNEL_FILE
	    exit 1
	fi
	echo "Not enough space to keep old image"
	[ "$CURRENT_IMAGE_NAME" != "" ] && rm -rf ${MNT_PATH}/boot/$CURRENT_IMAGE_NAME
    fi
fi

#--- Restore original kernel filename
NEW_IMAGE_NAME=`basename $KERNEL_FILE`
report "mv $KERNEL_FILE ${MNT_PATH}/boot/$NEW_IMAGE_NAME"
mv $KERNEL_FILE ${MNT_PATH}/boot/$NEW_IMAGE_NAME
if [ $? -ne 0 ]; then
    echo "Copy kernel file to ${MNT_PATH}/boot error"
    rm -f $KERNEL_FILE
    rm -f ${MNT_PATH}/boot/$NEW_IMAGE_NAME
    exit 1
fi

#--- backup old conf, then write the new grub config 
mv $GRUB_CONFIG $OLDGRUB_CONFIG 2>/dev/null

export SERIAL1="`grep '^serial --unit' $OLDGRUB_CONFIG`"
export SERIAL2="`grep '^terminal serial' $OLDGRUB_CONFIG`"

echo "Writing $GRUB_CONFIG"

#--- next kernel use ramdisk if initramfs file is not present
if ! [ -f `dirname $0`/initramfs ]; then

    report "Writing New kernel config : $NEW_IMAGE_NAME , $RAMDISK_OFFSET"
    cat > $GRUB_CONFIG << EOF

default=0
timeout=5
$SERIAL1
$SERIAL2
	 
title $NEW_IMAGE_NAME
	root (hd0,0)
	kernel /boot/$NEW_IMAGE_NAME $RAMDISK_OFFSET root=/dev/ram0 rw $CONSOLE current_image=$NEW_IMAGE_NAME $SAVED_CMDLINE
	initrd /boot/$NEW_IMAGE_NAME 
EOF

#--- next kernel use initramfs
else

    report "Writing New kernel config : $NEW_IMAGE_NAME"
    cat > $GRUB_CONFIG << EOF

default=0
timeout=5
$SERIAL1
$SERIAL2

title $NEW_IMAGE_NAME
	root (hd0,0)
	kernel /boot/$NEW_IMAGE_NAME $CONSOLE current_image=$NEW_IMAGE_NAME $SAVED_CMDLINE
EOF

fi
#--- write the rollback kernel config if we can
if [ "x$CURRENT_IMAGE_NAME" != "x" -a -f "${MNT_PATH}/boot/$CURRENT_IMAGE_NAME" -a "$CURRENT_IMAGE_NAME" != "$NEW_IMAGE_NAME" ]; then

    #--- rollback kernel use ramdisk
    if [ $IS_INITRAMFS = 0 ]; then
	report "Writing rollback kernel config : $CURRENT_IMAGE_NAME, $RAMDISK_OFFSET"

	cat >> $GRUB_CONFIG << EOF

title $CURRENT_IMAGE_NAME
	root (hd0,0)
	kernel /boot/$CURRENT_IMAGE_NAME ramdisk_start=$CURRENT_RAMDISKSIZE root=/dev/ram0 rw $CONSOLE current_image=$CURRENT_IMAGE_NAME $SAVED_CMDLINE
	initrd /boot/$CURRENT_IMAGE_NAME

EOF
    #--- rollback kernel use initramfs
    else
	report "Writing rollback kernel config : $CURRENT_IMAGE_NAME"

	cat >> $GRUB_CONFIG << EOF

title $CURRENT_IMAGE_NAME
	root (hd0,0)
	kernel /boot/$CURRENT_IMAGE_NAME $CONSOLE current_image=$CURRENT_IMAGE_NAME $SAVED_CMDLINE

EOF

    fi

else
    echo "Warning: cannot do rollback (no old image found)"
fi
