#!/bin/bash

echo "Making ISO image"

export EXEC_DIR="$PWD"
cd sys

cat isombr.sys pure64.sys kernel.sys monitor.bin > software.sys

#dd if=/dev/zero of=isodisk.img count=128 bs=1048576 > /dev/null 2>&1 || (echo err; exit 1)
dd if=software.sys of=isodisk.img conv=notrunc > /dev/null 2>&1   || (echo err; exit 1)

mkisofs -R -quiet  -cache-inodes -l  -o ../isodisk.iso -b software.sys   \
        -no-emul-boot .

cd $EXEC_DIR

# EOF


