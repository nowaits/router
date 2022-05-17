#!/bin/bash

PATH=/sbin:/usr/sbin:/usr/local/sbin:$PATH

KERNEL_FILE=$1
SCRIPT_PATH=$2
ROMFS_DIR=$3
OUTPUT=$4

OUTPUT_FILE=$OUTPUT_DIR/`cat $ROMFS_DIR/etc/bootname`

BOOTLOADER=grub-1
OUTFOLDER=/tmp/${RANDOM}${RANDOM}

IMAGE=disk.img
SECTOR_SIZE=512

HEAD_NUM=255
SEC_TRACK=63

PART1_SIZE=134217728 # 128MB
DISK_SIZE=402653184 # 384MB

part1_start=63 # for MBR
cyl_sz=$((${SEC_TRACK}*${HEAD_NUM}))
part2_start=$(( ( (${PART1_SIZE}/${SECTOR_SIZE})/${cyl_sz} + 1 ) * ${cyl_sz}))
part1_sz=$((${part2_start}-${part1_start}))
part2_sz=$(( ( ( (${DISK_SIZE} - (${part1_sz}*${SECTOR_SIZE}) )/${SECTOR_SIZE})/${cyl_sz} ) * ${cyl_sz}))


check_tools_present()
{
	which parted qemu-img sfdisk dd mtools ovftool
	if [ $? -eq 1 ]
	then
		echo "WARNING: OVA package won't be generated."
		echo -e "\tIt is likely that OVFTOOL is not installed on this machine."
		echo -e "\tAll these binaries must be in the PATH to be able to generate the OVA package:"
		echo -e "\tparted qemu-img sfdisk dd mtools ovftool"
		return 1
	fi
	case ${BOOTLOADER} in
		syslinux)
			which syslinux
			if [ $? -eq 1 ]
			then
				echo "ERROR: syslinux is not present but is selected as the bootloader"
				return 1
			fi
			;;
		grub-1)
			which grub
			if [ $? -eq 1 ]
			then
				echo "ERROR, grub-1 is not present but is selected as the bootloader"
				return 1
			fi

			;;
	esac
	return 0
}

create_disk_image()
{

	qemu-img create -f raw ${OUTFOLDER}/${IMAGE} ${DISK_SIZE}

	parted ${OUTFOLDER}/${IMAGE} mklabel msdos

	cat > ${OUTFOLDER}/partition << EOF_
unit: sectors

${OUTFOLDER}/${IMAGE}1 : start= ${part1_start}, size= ${part1_sz}, Id= 6, bootable
${OUTFOLDER}/${IMAGE}2 : start= ${part2_start}, size= ${part2_sz}, Id=83
${OUTFOLDER}/${IMAGE}3 : start=        0, size=        0, Id= 0
${OUTFOLDER}/${IMAGE}4 : start=        0, size=        0, Id= 0
EOF_


	sfdisk -f ${OUTFOLDER}/${IMAGE} < ${OUTFOLDER}/partition

	parted -s ${OUTFOLDER}/${IMAGE} mkfs 1 fat16
	parted -s ${OUTFOLDER}/${IMAGE} mkfs 2 ext2

	cat >${OUTFOLDER}/mtoolsrc << EOF__
drive z: file="${OUTFOLDER}/${IMAGE}" partition=1
  fat_bits=16
  mformat_only
EOF__

	MTOOLSRC=${OUTFOLDER}/mtoolsrc mmd z:/boot
	MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${KERNEL_FILE} z:/boot/bzImage
}


create_bootloader()
{
	case "${BOOTLOADER}" in
		syslinux)

			dd conv=notrunc bs=440 count=1 if=/usr/lib/syslinux/mbr.bin of=${OUTFOLDER}/${IMAGE}
			cat >${OUTFOLDER}/syslinux.cfg << EOF___
DEFAULT linux
timeout 300
prompt 1
serial 0 115200

LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL /boot/bzImage
  APPEND rw console=ttyS1,115200 fp_mask=-m0x1 fp_opts=-p3,-Q2,--nb-mbuf=16384
EOF___

			syslinux -t $((${SECTOR_SIZE}*${part1_start})) -i ${OUTFOLDER}/${IMAGE}

			date >${OUTFOLDER}/RELEASE_DATE

			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy syslinux.cfg z:/syslinux.cfg
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy RELEASE_DATE z:/RELEASE_DATE
			;;
		grub-1)
			cat >${OUTFOLDER}/menu.lst<<EOF_
serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
terminal serial
timeout 5
default 0

title 6WINDGate - 3 ports / 1 FP core
	root (hd0,0)
	kernel /boot/bzImage rw console=ttyS0,115200 fp_mask=-m0x1 fp_opts=-p7,-tc0=0:1:2,--nb-mbuf=16384
	boot

title 6WINDGate - 2 ports / 1 FP core
	root (hd0,0)
	kernel /boot/bzImage rw console=ttyS0,115200 fp_mask=-m0x1 fp_opts=-p3,-Q2,--nb-mbuf=16384
	boot

title 6WINDGate - 2 ports / 2 FP cores
	root (hd0,0)
	kernel /boot/bzImage rw console=ttyS0,115200 fp_mask=-m0x3 fp_opts=-p3,-Q1,--nb-mbuf=16384
	boot

EOF_

			MTOOLSRC=${OUTFOLDER}/mtoolsrc mmd z:/boot/grub
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${SCRIPT_PATH}/grub/default z:/boot/grub/default
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${SCRIPT_PATH}/grub/device.map  z:/boot/grub/device.map
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${SCRIPT_PATH}/grub/fat_stage1_5  z:/boot/grub/fat_stage1_5
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${SCRIPT_PATH}/grub/stage1  z:/boot/grub/stage1
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${SCRIPT_PATH}/grub/stage2  z:/boot/grub/stage2
			MTOOLSRC=${OUTFOLDER}/mtoolsrc mcopy ${OUTFOLDER}/menu.lst  z:/boot/grub/menu.lst

			read -r SECTORS <<EOF
`
grub --batch --device-map=/dev/NULL <<EOF2 | sed -n 's/^ *\([0-9][0-9]*\) sectors are embedded.*$/\1/p'
device (hd0) ${OUTFOLDER}/${IMAGE}
root (hd0,0)
embed /boot/grub/fat_stage1_5 (hd0)
quit
EOF2
`
EOF
			if [ -z "$SECTORS" ] || [ "$SECTORS" -eq 0 ]
			then
				echo 'Failed to get the number of sectors.'
				return 1
			fi
			grub --batch --device-map=/dev/null <<EOF_
device (hd0) ${OUTFOLDER}/${IMAGE}
root (hd0,0)
embed /boot/grub/fat_stage1_5 (hd0)
install /boot/grub/stage1 (hd0) (hd0)1+${SECTORS} p (hd0,0)/boot/grub/stage2 /boot/grub/menu.lst
quit
EOF_
			;;
		*)
			echo "bootloader not supported: "${BOOTLOADER}
			return 1
			;;
	esac
	return 0
}

create_ova_file()
{

	qemu-img convert -O vmdk ${OUTFOLDER}/${IMAGE} ${OUTFOLDER}/${IMAGE}.vmdk

	cat >${OUTFOLDER}/${OUTPUT_FILE}.vmx << EOF___
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "8"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
hpet0.present = "TRUE"
nvram = "${OUTPUT_FILE}.nvram"
virtualHW.productCompatibility = "hosted"
powerType.powerOff = "hard"
powerType.powerOn = "hard"
powerType.suspend = "hard"
powerType.reset = "hard"
displayName = "${OUTPUT_FILE}"
floppy0.present = "FALSE"
scsi0.present = "TRUE"
scsi0.sharedBus = "none"
scsi0.virtualDev = "lsilogic"
memsize = "2048"
ide0:0.present = "TRUE"
ide0:0.fileName = "${OUTFOLDER}/${IMAGE}.vmdk"
serial0.present = "TRUE"
serial0.yieldOnMsrRead = "TRUE"
serial0.fileType = "network"
serial0.fileName = "telnet://:7002"
cleanShutdown = "TRUE"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "vmxnet3"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.networkName = "LAN"
ethernet0.addressType = "vpx"
ethernet1.present = "TRUE"
ethernet1.virtualDev = "vmxnet3"
ethernet1.wakeOnPcktRcv = "FALSE"
ethernet1.networkName = "Management"
ethernet1.addressType = "vpx"
ethernet2.present = "TRUE"
ethernet2.virtualDev = "vmxnet3"
ethernet2.wakeOnPcktRcv = "FALSE"
ethernet2.networkName = "WAN"
ethernet2.addressType = "vpx"
chipset.onlineStandby = "FALSE"
guestOSAltName = "Linux"
guestOS = "other-64"
uuid.bios = "42 20 8c f7 44 7e 64 ae-af 87 b5 b2 30 11 c3 4f"
vc.uuid = "50 20 fe 1c cd fd bd a4-9f c4 25 9d 40 6f 83 35"
snapshot.action = "keep"
sched.cpu.min = "0"
sched.cpu.units = "mhz"
sched.cpu.shares = "normal"
sched.cpu.affinity = "all"
sched.mem.min = "0"
sched.mem.shares = "normal"
sched.mem.affinity = "all"
vmci0.id = "806470479"
uuid.location = "56 4d 35 dd 97 c4 f4 2f-d0 ab 73 95 26 11 d0 0d"
replay.supported = "FALSE"
replay.filename = ""
ide0:0.redo = ""
pciBridge0.pciSlotNumber = "17"
pciBridge4.pciSlotNumber = "21"
pciBridge5.pciSlotNumber = "22"
pciBridge6.pciSlotNumber = "23"
pciBridge7.pciSlotNumber = "24"
scsi0.pciSlotNumber = "16"
ethernet0.pciSlotNumber = "160"
ethernet1.pciSlotNumber = "192"
vmci0.pciSlotNumber = "32"
evcCompatibilityMode = "FALSE"
vmotion.checkpointFBSize = "4194304"
numvcpus = "4"
monitor_control.pseudo_perfctr = "TRUE"
EOF___

	echo "Opening VMX source: ${OUTFOLDER}/${OUTPUT_FILE}.vmx"
	echo "Writing OVA package: ${OUTPUT}/${OUTPUT_FILE}.ova"
	ovftool -st=vmx -tt=OVA -q ${OUTFOLDER}/${OUTPUT_FILE}.vmx ${OUTPUT}/${OUTPUT_FILE}.ova
}

cleanup_tmp()
{
	rm -rf ${OUTFOLDER}
}

create_tmp()
{
	mkdir -p ${OUTFOLDER}
}

if check_tools_present
then
	create_tmp
	create_disk_image
	if create_bootloader
	then
		create_ova_file
	fi
	cleanup_tmp
fi

