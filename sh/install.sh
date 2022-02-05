#!/bin/sh

#set -e

EXEC_DIR="$PWD"

cd sys
echo Building OS image...

if [ "$1" != "" ]; then
	cat mbr.sys second.sys fill.img disk.img pure64.sys kernel.sys $1 > software.sys
else
	cat mbr.sys second.sys fill.img disk.img pure64.sys kernel.sys null.bin > software.sys
fi

dd if=../src/bootsectors/bin/mpr.sys bs=512 of=harddisk.img conv=notrunc status=none
dd if=software.sys of=harddisk.img bs=512 seek=2048 conv=notrunc status=none

cd $EXEC_DIR


