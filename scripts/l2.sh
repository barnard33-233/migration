#!/bin/sh

BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs.cpio

L2NCPU=1

qemu-system-aarch64 -serial /dev/hvc1 -monitor /dev/hvc2 \
    -M 'virt,acpi=off,gic-version=3' -cpu host -enable-kvm -smp $L2NCPU -m 512M -overcommit 'mem-lock=on' \
    -M 'confidential-guest-support=rme0' \
    -object 'rme-guest,id=rme0,measurement-algo=sha512,migration-cap=dev' \
    -kernel $IMAGE_PATH -initrd $ROOTFS_PATH -append 'rcu_cpu_stall_timeout=0 nokaslr earycon console=ttyAMA0 rdinit=/sbin/init abi.ptrauth_disabled=1' \
    -nographic \
    -net none --trace migrat*
