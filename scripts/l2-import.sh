#!/bin/sh

BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs.cpio
INCOMING_PATH=/mnt/mig.img

qemu-system-aarch64 \
     -serial /dev/hvc1 \
     -monitor /dev/hvc2 \
     -M 'virt,acpi=off' -cpu host,pauth=off -enable-kvm -smp 1 -m 512M \
     -overcommit 'mem-lock=on' -M 'confidential-guest-support=rme0' \
     -object 'rme-guest,id=rme0,measurement-algo=sha512,migration-cap=dev' \
     -kernel $IMAGE_PATH -initrd $ROOTFS_PATH \
     -append 'nokaslr earycon console=ttyAMA0 rdinit=/sbin/init cpuidle.off=1' \
     -net none \
     -nographic \
     --incoming "exec: cat $INCOMING_PATH" \
     --trace ram_load* --trace migrat*
