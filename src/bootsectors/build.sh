#!/bin/bash

mkdir -p bin

# echo Bootsectors
#nasm partboot.asm -o ./bin/partboot.sys || echo ERROR;  exit 1

nasm isombr.asm -o ./bin/isombr.sys #|| echo ERROR;  exit 1
nasm mbr.asm -o ./bin/mbr.sys  #|| echo ERROR;  exit 1
nasm second.asm -o ./bin/second.sys  #|| echo ERROR;  exit 1
nasm pxestart.asm -o ./bin/pxestart.sys  #|| echo ERROR;  exit 1
nasm multiboot.asm -o ./bin/multiboot.sys  #|| echo ERROR;  exit 1
nasm multiboot2.asm -o ./bin/multiboot2.sys # || echo ERROR;  exit 1

nasm mpr.asm -o ./bin/mpr.sys -l mpr.lst # ||  echo ERROR; exit 1
# Patch in dummy fdisk data
dd if=mpr.bin bs=1 skip=446 seek=446 count=64 of=./bin/mpr.sys conv=notrunc status=none #|| echo ERROR; exit 1



