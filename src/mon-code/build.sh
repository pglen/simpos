#!/bin/bash

export EXEC_DIR="$PWD"
cd src

../../../sh/cmpdate.sh ../bin/monitor.bin  *.asm  *.inc
if [ "$?" != "0" ] ; then
    echo " Compile monitor.asm"
    nasm -I../../common/ monitor.asm -o ../bin/monitor.bin -l ../bin/monitor-debug.txt
    RET=$?
fi
cd $EXEC_DIR
exit $RET
