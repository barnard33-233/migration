#source ~/.gdbinit-gef.py
set disassemble-next-line on
add-symbol-file rmm/build-qemu/Debug/rmm.elf 0x40100000
add-symbol-file linux/vmlinux

target remote :1236
