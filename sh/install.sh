#!/bin/sh

#set -e

export EXEC_DIR="$PWD"
export OUTPUT_DIR="$PWD/sys"

cd "$OUTPUT_DIR"
echo Building OS image...

if [ "$1" != "" ]; then
	cat disk.img pure64.sys kernel.sys $1 > software.sys
else
	cat disk.img pure64.sys kernel.sys null.bin > software.sys
fi

dd if=../stock/mbr.bin bs=512 of=harddisk.img conv=notrunc > /dev/null 2>&1
dd if=software.sys of=harddisk.img bs=512 seek=2048 conv=notrunc > /dev/null 2>&1
dd if=mbr.sys bs=512 count=1 of=harddisk.img conv=notrunc > /dev/null 2>&1

cd $EXEC_DIR
