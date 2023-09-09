# 嵌入式系统

## 工具依赖

- kvm
  - centos:
    ```
    yum install -y qemu-kvm lsof telnet
    ```
  - ubuntu:
    ```
    apt-get install libgmp-dev # gdb
    ```
  - `systemctl restart libvirtd`
  - `kvm -cpu help`
  - `kvm -device help`

## 源码下载至:`~/Downloads`目录

- [linux](https://www.kernel.org/)
  - 2x: `https://mirrors.edge.kernel.org/pub/linux/kernel/v2.6/linux-2.6.34.tar.xz`
  - 4x: `https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.243.tar.xz`
  - 5x: `https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.18.tar.xz`
- busybox: `https://www.busybox.net/downloads/busybox-1.35.0.tar.bz2`
- bash: `https://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz`
- pciutils: `https://codeload.github.com/pciutils/pciutils/tar.gz/refs/tags/v3.7.0`
- python: `https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz`
- openssl: `https://www.openssl.org/source/openssl-1.0.2l.tar.gz`
- openssh: `http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz`
- gdb: `https://ftp.gnu.org/gnu/gdb/gdb-12.1.tar.xz`
  - yum install -y gmp-devel
- sudo: `https://www.sudo.ws/dist/sudo-1.9.9.tar.gz`
- tree: `http://mama.indstate.edu/users/ice/tree/src/tree-1.8.0.tgz`

### 内核调试

- 编译：`make KERNEL_DEBUG=on`
- 运行：
  - 调试运行：`make runkvm args="-g"`
  - 切换网卡类型：`make runkvm args="-n=virtio"`
- gdb连接：`make gdb`

### 编译

- debug: `make`
- release: `make release`
- 仅编译内核：`make BUILD_ONLY_KERNEL=true`

### 硬盘挂载

- 创建：`qemu-img create -f qcow2 /tmp/v.qcow2 10G`
- 启动：`make runkvm disk=/tmp/v.qcow2`

### 默认账户

- root/a
- admin/a

### 创建桥接

```
brctl addbr br0
brctl addif br0 eth0
brctl stp br0 on
echo "allow br0" >> /etc/qemu-kvm/bridge.conf
```

### 工具集合

- lspci
- openssl
- sshd
- python 2.7
- kexec
- lscpu
- tcpdump
- sudo
- gdb
- tree

### ISSUES

- python模块编译未正确使用编译的openssl，导致相关模块编译出错