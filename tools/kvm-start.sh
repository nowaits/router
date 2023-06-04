#!/bin/bash
set -e

mem=4096
cores=4

cmdline="console=ttyS0 earlyprintk=ttyS0,115200"

get_free_tcp_port () {
	port=$1
	while [ $port -lt 10000 ] ; do
		lsof -iTCP:$port >&- || break
		let port+=1
	done
	echo $port
}

ROOT_DIR=`realpath $(dirname $0)`
cd $ROOT_DIR

usage() {
    cat <<EOF
Usage: ${0##*/} OPTIONS -- cmd

OPTIONS:
  -g/--gdb			gdb debug
  -k/--kernel    	kernel
  -n/--nic			nic type: (e1000|virtio)
  -h/--help         help
EOF
    exit 1
}

HDA=
KERNEL=
GDB_ARG=
NIC_TYPE=e1000

for i in "$@"
do
case $i in
    -g|--gdb)
        GDB_ARG="-S -gdb tcp::1234"
    shift
    ;;
    -k=*|--kernel=*)
        KERNEL="-kernel ${i#*=} -append \"$cmdline\""
    shift
    ;;
    -n=*|--nic=*)
        NIC_TYPE="${i#*=}"
		if [ $NIC_TYPE != e1000 ] && [ $NIC_TYPE != virtio ]; then
			echo "Nic:${NIC_TYPE} should be in (e1000|virtio)!";
			false;
		fi
    shift
    ;;
    --)
    shift
        break
    ;;
    *)
        usage
    ;;
esac
done

serial_port=$(get_free_tcp_port 3000)
echo "localhost:$serial_port -> KVM:serial"
echo "	grabbing with telnet"
ssh_port=$(get_free_tcp_port 2222)
echo "localhost:$ssh_port -> KVM:22"
echo "	ssh -p $ssh_port root@localhost"

new_mac() {
	hexdump -n3 -e'/3 "00:60:2F" 3/1 ":%02X"' /dev/random
}
clean () {
	[ -e "$pidfile" ] || return
	echo Shutdown VM
	[ -d /proc/$(cat $pidfile) ] && kill $(cat $pidfile)
	rm -f $pidfile
}

pidfile=/tmp/kvm-$$.pid
trap clean EXIT SIGINT SIGQUIT SIGTERM
eval \
"kvm -daemonize -pidfile $pidfile -display none -monitor null \
	-cpu host -smp $cores -m $mem ${GDB_ARG} \
	-serial telnet::$serial_port,server,wait \
	-net bridge,br=virbr0 \
	-net nic,model=${NIC_TYPE},macaddr=`new_mac` \
	-net nic,model=${NIC_TYPE},macaddr=`new_mac` \
	-net nic,model=${NIC_TYPE},macaddr=`new_mac` \
	-net nic,model=${NIC_TYPE},macaddr=`new_mac` \
	$KERNEL $* & \
"

try_time=30
while [ $try_time -gt 0 ]; do
	let try_time-=1
	sleep 1
	lsof -iTCP:$serial_port >&- && break
done

[ $? -ne  0 ] || telnet 127.0.0.1 $serial_port