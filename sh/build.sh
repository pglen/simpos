#!/bin/bash
# ------------------------------------------------------------------------
# Bash shell job to build this project
#
# Crude but effective.
#
# Sat 30.Oct.2021       Created
# Sat 29.Jan.2022       Moved boot secors
#
# ------------------------------------------------------------------------

EXEC_DIR="$PWD"
OUTPUT_DIR="$EXEC_DIR/sys"

function build_dir {
	#echo "Building $1 ..."
	cd "$1"
	if [ -e "build.sh" ]; then
		./build.sh
        RET=$?
    #fi
	elif [ -e "install.sh" ]; then
		./install.sh
        RET=$?
	#fi
	elif [ -e "Makefile" ]; then
		make --quiet
        RET=$?
    else
        echo "No build method"
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

# Start with new dirs

rm -f sys/*

mkdir -p sys
mkdir -p src/mon-code/bin
mkdir -p src/app-code/bin
mkdir -p src/os-code/bin
mkdir -p src/simpos64/bin

echo Creating disk image...
#cd sys

# Start fresh

dd if=/dev/zero of=sys/harddisk.img count=128 bs=1048576 > /dev/null 2>&1
dd if=/dev/zero of=sys/disk.img count=16 bs=512 > /dev/null 2>&1
dd if=/dev/zero of=sys/fill.img count=4 bs=512 > /dev/null 2>&1
dd if=/dev/zero of=sys/null.bin count=8 bs=1 > /dev/null 2>&1

cd $EXEC_DIR

#echo Building components ...

build_dir "src/bootsectors" || exit 1
build_dir "src/simpos64" || exit 1
build_dir "src/os-code" || exit 1
build_dir "src/mon-code" || exit 1
build_dir "src/app-code" || exit 1
build_dir "src/BMFS" || exit 1

#echo Copying components ...

copy_file "src/bootsectors/bin/isombr.sys" "${OUTPUT_DIR}/isombr.sys"
copy_file "src/bootsectors/bin/mbr.sys" "${OUTPUT_DIR}/mbr.sys"
copy_file "src/bootsectors/bin/second.sys" "${OUTPUT_DIR}/second.sys"
copy_file "src/simpos64/bin/pure64.sys" "${OUTPUT_DIR}/pure64.sys"
copy_file "src/os-code/bin/kernel.sys" "${OUTPUT_DIR}/kernel.sys"
copy_file "src/mon-code/bin/monitor.bin" "${OUTPUT_DIR}/monitor.bin"

# Various ... mostly test cases

#copy_file "src/os-code/bin/kernel-debug.txt" "${OUTPUT_DIR}/kernel-debug.txt"
#copy_file "src/bootsectors/bin/multiboot.sys" "${OUTPUT_DIR}/multiboot.sys"
#copy_file "src/bootsectors/bin/multiboot2.sys" "${OUTPUT_DIR}/multiboot2.sys"
#copy_file "src/simpos64/bin/pxestart.sys" "${OUTPUT_DIR}/pxestart.sys"
#copy_file "src/mon-code/bin/monitor-debug.txt" "${OUTPUT_DIR}/monitor-debug.txt"
#copy_file "src/BMFS/bin/bmfs" "${OUTPUT_DIR}/bmfs"

cd sys
../src/BMFS/bin/bmfs disk.img format  #|| echo ERROR; exit 1

cd $EXEC_DIR

./sh/install.sh monitor.bin # || echo ERROR; exit 1
./sh/install-demos.sh  #|| echo ERROR; exit 1

# EOF
