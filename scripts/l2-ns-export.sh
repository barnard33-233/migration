#!/bin/sh

BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs.cpio

L2NCPU=1

qemu-system-aarch64 \
    -serial /dev/hvc1 \
    -monitor /dev/hvc2 \
    -M 'virt,acpi=off,gic-version=3' -cpu host,kvm-steal-time=off,kvm-no-adjvtime=on -enable-kvm -smp $L2NCPU -m 512M \
    -overcommit 'mem-lock=on' \
    -kernel $IMAGE_PATH -initrd $ROOTFS_PATH \
    -append 'rcu_cpu_stall_timeout=0 nokaslr earlycon console=ttyAMA0 rdinit=/sbin/init' \
    -nographic \
    -net none
