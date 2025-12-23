#!/bin/sh
BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs-2.cpio
INCOMING_ADDR=:6666

L2NCPU=1

ip addr add 192.168.100.5/24 dev eth0
ip link set eth0 up

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
    -net none \
    --incoming "tcp:$INCOMING_ADDR" \
