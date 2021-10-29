#!/bin/bash

echo "Making ISO image"

cd sys

cat isombr.sys pure64.sys kernel.sys monitor.bin > software.sys

dd if=/dev/zero of=isodisk.img count=128 bs=1048576 > /dev/null 2>&1 || (echo err; exit 1)
dd if=software.sys of=isodisk.img conv=notrunc > /dev/null 2>&1   || (echo err; exit 1)

mkisofs -quiet  -cache-inodes -l  -o ../isodisk.iso -b isodisk.img  -c boot/boot.catalog  \
        -no-emul-boot -boot-load-size 128 .

cd ..

# EOF