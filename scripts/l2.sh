BINARY_PATH=/mnt/out/bin/
IMAGE_PATH=$BINARY_PATH/Image-guest
ROOTFS_PATH=$BINARY_PATH/br/rootfs.cpio

qemu-system-aarch64 -serial stdio -monitor telnet:127.0.0.1:1234,server,nowait \
    -M 'virt,acpi=off,gic-version=3' -cpu host -enable-kvm -smp 1 -m 512M -overcommit 'mem-lock=on' \
    -M 'confidential-guest-support=rme0' \
    -object 'rme-guest,id=rme0,measurement-algo=sha512,migration-cap=dev' \
    -kernel $IMAGE_PATH -initrd $ROOTFS_PATH -append 'earycon console=ttyAMA0 rdinit=/sbin/init abi.ptrauth_disabled=1' -nographic \
    -net none --trace migrat*
