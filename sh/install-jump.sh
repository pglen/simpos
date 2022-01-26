#!/bin/sh

set -e

JMP=/dev/sdd1

export OUTPUT_DIR="$PWD/sys"
cd "$OUTPUT_DIR"
echo Installing OS image to jump drive $JMP ...
echo "This can cause harm ... Verified? [y/n] (Ctrl-C to stop)"
read Y

if [ "$Y" != "y" -a  "$Y" != "Y"] ; then
    echo "Aborting write"
    exit 0
fi

echo "Copying ..."

sudo dd status=progress if=disk.img of=$JMP bs=512 conv=notrunc #> /dev/null 2>&1

cd $EXEC_DIR

