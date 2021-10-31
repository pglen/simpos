#!/bin/bash

export EXEC_DIR="$PWD"

cd src
nasm pure64.asm -o ../bin/pure64.sys  || exit 1

cd bootsectors
nasm isombr.asm -o ../../bin/isombr.sys || exit 1
nasm mbr.asm -o ../../bin/mbr.sys  || exit 1
nasm pxestart.asm -o ../../bin/pxestart.sys  || exit 1
nasm multiboot.asm -o ../../bin/multiboot.sys  || exit 1
nasm multiboot2.asm -o ../../bin/multiboot2.sys  || exit 1

cd $EXEC_DIR

