#!/bin/bash

EXEC_DIR="$PWD"
cd src
../../../sh/cmpdate.sh ../bin/pure64.sys  *.asm init/*.asm

if [ "$?" != "0" ] ; then
    nasm pure64.asm -o ../bin/pure64.sys -l ../bin/pure64.lst || exit 1
fi

cd $EXEC_DIR

