#!/bin/sh

for arg in `cat /proc/cmdline`; do
        if [ "${arg:0:8}" == "console=" ]; then
                line=`echo $arg | cut -f 2 -d '='`
                device=`echo $line | cut -f 1 -d ','`
                bauds=`echo $line | cut -f 2 -d ',' | awk -F '[a-zA-Z:-]' '{ print $1 }'`
				# bauds is empty when there is no comma
				if [ -z "$bauds" ]; then
					bauds=9600
				fi
        fi
done

if [ -z "$device" ]; then
    echo "Console device not found"
    sed -i 's,^# setconsole_default=,,' /etc/inittab
    kill -HUP 1
    exit 0
fi

# build new inittab in /tmp
cp /etc/inittab /tmp/inittab_temp

# default options to add
OPTS=$(grep '^# setconsole_opts=' /etc/inittab | sed 's,^# setconsole_opts=,,')

# handle special device pci
if [ "${device:0:3}" = "pci" ]; then
	device=ttyPCI${device:3}
fi

echo "::respawn:/sbin/getty -L $bauds $device vt102 $OPTS" >> /tmp/inittab_temp

# move new inittab in /var/tmp/inittab
mv /tmp/inittab_temp /var/tmp/inittab

# reload init
kill -HUP 1