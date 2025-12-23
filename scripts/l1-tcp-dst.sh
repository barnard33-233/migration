#!/bin/bash
ROOT=/home/mohan/dev/migration
BINARIES_PATH=$ROOT/out/bin
QEMU_BUILD=$ROOT/qemu/build
BUILDROOT_BINARIES_PATH=$BINARIES_PATH/br/

FLASH_BIN_PATH=$BINARIES_PATH/flash-2.bin
IMAGE_PATH=$BINARIES_PATH/Image-2
IMAGE_GUEST_PATH=$BINARIES_PATH/Image-guest
ROOTFS_PATH=$BUILDROOT_BINARIES_PATH/rootfs-2.ext4
ROOTFS_L2_PATH=$BUILDROOT_BINARIES_PATH/rootfs-2.cpio

PORT0=56424
PORT1=56425
PORT2=56426
PORT3=56427

PORT_SSH=56431

NCPU=2
MEMSIZE=4G

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

# Create a Tmux session "cca-dst" in a window "window0" started in the background.
echo "Creating tmux session."
tmux new -d -s cca-dst -n window0

# Split the window to 4 panes.
tmux split-window -h -t cca-dst:window0
tmux split-window -v -t cca-dst:window0.0
tmux split-window -v -t cca-dst:window0.2

tmux send -t cca-dst:window0.0 "socat -,rawer TCP-LISTEN:$PORT0" ENTER # Firmware
tmux send -t cca-dst:window0.1 "socat -,rawer TCP-LISTEN:$PORT1" ENTER # Host
tmux send -t cca-dst:window0.2 "socat -,rawer TCP-LISTEN:$PORT2" ENTER # Monitor
tmux send -t cca-dst:window0.3 "socat -,rawer TCP-LISTEN:$PORT3" ENTER # Realm
tmux select-window -t cca-dst:window0.1

ssh-keygen -f '/home/mohan/.ssh/known_hosts' -R "[127.0.0.1]:$PORT_SSH"
sleep 1

# start host qemu
echo "Starting host qemu"
cd $BINARIES_PATH && $QEMU_BUILD/qemu-system-aarch64 \
    -M virt,virtualization=on,secure=on,gic-version=3 \
    -M acpi=off -cpu max,x-rme=on,sme=off -m $MEMSIZE -smp $NCPU \
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
    -append "rcu_cpu_stall_timeout=0 nokaslr root=/dev/vda earlycon console=hvc0" \
    -netdev tap,id=net3,ifname=tap3,script=no,downscript=no \
    -device virtio-net-pci,netdev=net3,mac=52:54:00:12:34:59 \
    -device virtio-9p-device,fsdev=shr0,mount_tag=shr0 \
    -fsdev local,security_model=none,path=../../,id=shr0 
