#!/bin/bash

export EXEC_DIR="$PWD"
cd src

mkdir -p bin

# We take advantage of shell expansion on specifing dependencies
../../../sh/cmpdate.sh ../bin/kernel.sys  *.asm \
     init/*.asm syscalls/*.asm drivers/*.asm drivers/net/*.asm \
     drivers/storage/*.asm

if [ "$?" != "0" ] ; then
    echo " Compile kernel.asm"
    nasm kernel.asm -o ../bin/kernel.sys -l ../bin/kernel-debug.txt
    RET=$?
fi

cd $EXEC_DIR
exit $RET
