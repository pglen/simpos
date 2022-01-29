#!/bin/bash

EXEC_DIR="$PWD"
cd src
nasm pure64.asm -o ../bin/pure64.sys -l ../bin/pure64.lst || exit 1
cd $EXEC_DIR

