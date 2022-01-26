#!/bin/bash
# ------------------------------------------------------------------------
# Bash shell job to build this project
#
# Crude but effective batch job to build stuff
#
# Created on Sat 30.Oct.2021
# ------------------------------------------------------------------------

export EXEC_DIR="$PWD"
export OUTPUT_DIR="$EXEC_DIR/sys"

function build_dir {
	echo "Building $1 ..."
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

    if [ $RET != 0 ] ; then
        echo Error $RET on building $1
        exit 1
    fi
    return $RET
}

function update_file {
	mv "$1" "$2"
    if [ $? != 0 ] ; then
        echo Error on $1
        exit 1
    fi
    return $?
}

function copy_file {
	cp -a "$1" "$2"
    if [ $? != 0 ] ; then
        echo Error on $1
        exit 1
    fi
    return $?
}

rm -f sys/*

mkdir -p sys
mkdir -p src/mon-code/bin
mkdir -p src/app-code/bin
mkdir -p src/os-code/bin
mkdir -p src/simpos64/bin

echo Creating disk image...
cd sys
dd if=/dev/zero of=disk.img count=128 bs=1048576 > /dev/null 2>&1
dd if=/dev/zero of=null.bin count=8 bs=1 > /dev/null 2>&1

cd $EXEC_DIR

#echo Building components ...

build_dir "src/simpos64" || exit 1
build_dir "src/os-code" || exit 1
build_dir "src/mon-code" || exit 1
build_dir "src/app-code" || exit 1
build_dir "src/BMFS" || exit 1

#echo Copying components ...
copy_file "src/simpos64/bin/isombr.sys" "${OUTPUT_DIR}/isombr.sys"
copy_file "src/simpos64/bin/mbr.sys" "${OUTPUT_DIR}/mbr.sys"
copy_file "src/simpos64/bin/second.sys" "${OUTPUT_DIR}/second.sys"
copy_file "src/simpos64/bin/multiboot.sys" "${OUTPUT_DIR}/multiboot.sys"
copy_file "src/simpos64/bin/multiboot2.sys" "${OUTPUT_DIR}/multiboot2.sys"
copy_file "src/simpos64/bin/pure64.sys" "${OUTPUT_DIR}/pure64.sys"
copy_file "src/simpos64/bin/pxestart.sys" "${OUTPUT_DIR}/pxestart.sys"
copy_file "src/os-code/bin/kernel.sys" "${OUTPUT_DIR}/kernel.sys"
#copy_file "src/os-code/bin/kernel-debug.txt" "${OUTPUT_DIR}/kernel-debug.txt"
copy_file "src/mon-code/bin/monitor.bin" "${OUTPUT_DIR}/monitor.bin"
#copy_file "src/mon-code/bin/monitor-debug.txt" "${OUTPUT_DIR}/monitor-debug.txt"
#copy_file "src/BMFS/bin/bmfs" "${OUTPUT_DIR}/bmfs"

cd sys
../src/BMFS/bin/bmfs disk.img format

cd $EXEC_DIR

./sh/install.sh monitor.bin
./sh/install-demos.sh

