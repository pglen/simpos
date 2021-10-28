#!/bin/bash

echo "Making jump drive"
#dd if=sys/disk.img of=/dev/sdf bs=512 status=progress
mkisofs -R -v -cache-inodes -l  -o disk.iso -b disk.img  -c disk.img \
        -no-emul-boot -boot-load-size 4 .