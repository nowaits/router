export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LD_LIBRARY_PATH=/lib64
export EDITOR=vi
export KERNEL_BOOT_FILE=kernel
if [ "$USER" = "root" ]; then
    PS1='\u@\h:\w# '
else
    PS1='$USER@\h:\w> '
    cli
fi

# enable coredump if enough ram
mem=`grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'`
if [ ! -z "$mem" ]; then
    if [ "$mem" -gt 120000 ]; then
        ulimit -c unlimited
    fi
fi
