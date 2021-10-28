#!/bin/bash

echo "Making ISO image"
#dd if=sys/disk.img of=/dev/sdf bs=512 status=progress
echo $(pwd)
mkisofs -R -v -cache-inodes -l  -o disk.iso -b isolinux.bin  -c multiboot.sys  \
        -no-emul-boot -boot-load-size 4 .