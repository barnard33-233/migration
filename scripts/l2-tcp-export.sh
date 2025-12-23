#!/bin/sh

BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs.cpio

L2NCPU=1

ip addr add 192.168.100.4/24 dev eth0
ip link set eth0 up

# ip link add br0 type bridge
# ip link set br0 up
# ip addr add 192.168.100.6/24 dev br0
# 
# ip link set eth0 master br0
# 
# ip tuntap add dev tap0 mode tap
# ip link set tap0 up
# ip link set tap0 master br0

qemu-system-aarch64 \
    -serial /dev/hvc1 \
    -monitor /dev/hvc2 \
    -M 'virt,acpi=off,gic-version=3' -cpu host -enable-kvm -smp $L2NCPU -m 512M \
    -overcommit 'mem-lock=on' \
    -M 'confidential-guest-support=rme0' \
    -object 'rme-guest,id=rme0,measurement-algo=sha512,migration-cap=dev' \
    -kernel $IMAGE_PATH -initrd $ROOTFS_PATH \
    -append 'rcu_cpu_stall_timeout=0 nokaslr earlycon console=ttyAMA0 rdinit=/sbin/init' \
    -nographic \
    -net none
    # -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
    # -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:dd,romfile= \
