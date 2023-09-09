ROMFS_DIR=$1
# Create link 
cd $ROMFS_DIR/etc
ln -nfs /usr/admin/etc/passwd passwd
ln -nfs /usr/admin/etc/shadow shadow
ln -nfs /var/tmp/shells/network.conf inetd.conf
ln -nfs /var/tmp/shells/hosts hosts
ln -nfs /var/tmp/shells/resolv.conf resolv.conf
ln -nfs /var/tmp/inittab inittab
cd $ROMFS_DIR
ln -nfs /var/tmp tmp
cd $ROMFS_DIR/root
mkdir .ssh
if [ -f ~/.ssh/id_rsa.pub ]; then
    cp ~/.ssh/id_rsa.pub .ssh/authorized_keys
fi
ln -nfs /usr/admin/.profile .profile