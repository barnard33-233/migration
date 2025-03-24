#!/bin/bash
ROOT=/home/mohan/dev/migration
BINARIES_PATH=$ROOT/out/bin
QEMU_BUILD=$ROOT/qemu/build
BUILDROOT_BINARIES_PATH=$BINARIES_PATH/br/

FLASH_BIN_PATH=$BINARIES_PATH/flash.bin
IMAGE_PATH=$BINARIES_PATH/Image
IMAGE_GUEST_PATH=$BINARIES_PATH/Image-guest
ROOTFS_PATH=$BUILDROOT_BINARIES_PATH/rootfs.ext4
ROOTFS_L2_PATH=$BUILDROOT_BINARIES_PATH/rootfs.cpio

PORT0=56420
PORT1=56421
PORT2=56422
PORT3=56423

PORT_SSH=5924
PORT_MONITOR=5925

echo "Copying files."
rm -f $IMAGE_PATH
rm -f $FLASH_BIN_PATH
rm -f $ROOTFS_PATH
rm -f $ROOTFS_L2_PATH
cp $ROOT/linux/arch/arm64/boot/Image $IMAGE_PATH
cp $ROOT/linux-guest/arch/arm64/boot/Image $IMAGE_GUEST_PATH
cp $ROOT/trusted-firmware-a/flash.bin $FLASH_BIN_PATH
cp $ROOT/buildroot/output/images/rootfs.ext4 $ROOTFS_PATH
cp $ROOT/buildroot-l2/output/images/rootfs.cpio $ROOTFS_L2_PATH


handle_sigint() {
    exit 0
}

trap 'handle_sigint' SIGINT

# Create a Tmux session "cca-mohan" in a window "window0" started in the background.
echo "Creating tmux session."
tmux new -d -s cca-mohan -n window0

# Split the window to 4 panes.
tmux split-window -h -t cca-mohan:window0
tmux split-window -v -t cca-mohan:window0.0
tmux split-window -v -t cca-mohan:window0.2

tmux send -t cca-mohan:window0.0 "socat -,rawer TCP-LISTEN:$PORT0" ENTER # Firmware
tmux send -t cca-mohan:window0.1 "socat -,rawer TCP-LISTEN:$PORT1" ENTER # host
tmux send -t cca-mohan:window0.2 "socat -,rawer TCP-LISTEN:$PORT2" ENTER # Secure
tmux send -t cca-mohan:window0.3 "socat -,rawer TCP-LISTEN:$PORT3" ENTER # Realm
tmux select-window -t cca-mohan:window0.1

ssh-keygen -f '/home/mohan/.ssh/known_hosts' -R "[127.0.0.1]:$PORT_SSH"
sleep 1 # XXX totally rubbish

# start host qemu
echo "Starting host qemu"
cd $BINARIES_PATH && $QEMU_BUILD/qemu-system-aarch64 -gdb tcp::1236 -S\
    -M virt,virtualization=on,secure=on,gic-version=3 \
    -M acpi=off -cpu max,x-rme=on,sme=off -m 4G -smp 1 \
    -nographic \
    -bios $FLASH_BIN_PATH \
    -kernel $IMAGE_PATH \
    -drive format=raw,if=none,file=$ROOTFS_PATH,id=hd0 \
    -device virtio-blk-pci,drive=hd0 \
    -append root=/dev/vda \
    -nodefaults \
    -serial tcp:localhost:$PORT0 \
    -chardev socket,mux=on,id=hvc0,port=$PORT1,host=localhost \
    -device virtio-serial-device \
    -device virtconsole,chardev=hvc0 \
    -chardev socket,mux=on,id=hvc1,port=$PORT3,host=localhost \
    -device virtio-serial-device \
    -device virtconsole,chardev=hvc1 \
    -chardev socket,mux=on,id=hvc2,port=$PORT2,host=localhost \
    -device virtio-serial-device \
    -device virtconsole,chardev=hvc2 \
    -append "nokaslr root=/dev/vda earlycon console=hvc0" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::$PORT_SSH-:22,hostfwd=tcp::$PORT_MONITOR-:1234\
    -device virtio-9p-device,fsdev=shr0,mount_tag=shr0 \
    -fsdev local,security_model=none,path=../../,id=shr0 

## Attach the Tmux session to the front.
# tmux a -t cca-mohan
# original one here:
#/home/mohan/dev/migration/flash.bin
