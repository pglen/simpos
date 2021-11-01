#!/bin/sh

export EXEC_DIR="$PWD"
export OUTPUT_DIR="$EXEC_DIR/sys"

#echo Copying apps ...

saveapp() {
    ../src/BMFS/bin/bmfs disk.img create $1 2
    ../src/BMFS/bin/bmfs disk.img write $1
}

cd $OUTPUT_DIR
cp ../src/app-code/bin/*.app .

saveapp hello.app
saveapp sysinfo.app
saveapp counter.app
saveapp helloc.app
saveapp gavare.app
saveapp graphics.app

saveapp helloc2.app
saveapp helloc3.app
saveapp helloc4.app
saveapp helloc5.app

cd $EXEC_DIR

# EOF
