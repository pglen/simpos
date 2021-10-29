#!/bin/bash

#set -e
#set -u

export EXEC_DIR="$PWD"
export OUTPUT_DIR="$EXEC_DIR/sys"

function build_dir {
	echo "Building $1..."
	cd "$1"
	if [ -e "build.sh" ]; then
		./build.sh
        RET=$?
    fi
	if [ -e "install.sh" ]; then
		./install.sh
        RET=$?
	fi
	if [ -e "Makefile" ]; then
		make --quiet
        RET=$?
	fi
    #echo "ret" $RET
	cd "$EXEC_DIR"
    return $RET
}

function update_file {
	mv "$1" "$2"
}

function copy_file {
	cp -a "$1" "$2"
}

mkdir -p sys
mkdir -p src/mon-code/bin
mkdir -p src/app-code/bin

echo Creating disk image...
cd sys
dd if=/dev/zero of=disk.img count=128 bs=1048576 > /dev/null 2>&1
dd if=/dev/zero of=null.bin count=8 bs=1 > /dev/null 2>&1
cd ..

build_dir "src/Pure64" || exit 1
build_dir "src/BMFS" || exit 1
build_dir "src/os-code" || exit 1
build_dir "src/mon-code" || exit 1
build_dir "src/app-code" || exit 1

update_file "src/Pure64/bin/mbr.sys" "${OUTPUT_DIR}/mbr.sys"
update_file "src/Pure64/bin/multiboot.sys" "${OUTPUT_DIR}/multiboot.sys"
update_file "src/Pure64/bin/multiboot2.sys" "${OUTPUT_DIR}/multiboot2.sys"
update_file "src/Pure64/bin/pure64.sys" "${OUTPUT_DIR}/pure64.sys"
update_file "src/Pure64/bin/pxestart.sys" "${OUTPUT_DIR}/pxestart.sys"
update_file "src/os-code/bin/kernel.sys" "${OUTPUT_DIR}/kernel.sys"
update_file "src/os-code/bin/kernel-debug.txt" "${OUTPUT_DIR}/kernel-debug.txt"
update_file "src/BMFS/bin/bmfs" "${OUTPUT_DIR}/bmfs"
copy_file   "src/mon-code/bin/monitor.bin" "${OUTPUT_DIR}/monitor.bin"
copy_file   "src/mon-code/bin/monitor-debug.txt" "${OUTPUT_DIR}/monitor-debug.txt"

cd sys
./bmfs disk.img format
cd ..
./sh/install.sh monitor.bin
./sh/install-demos.sh

