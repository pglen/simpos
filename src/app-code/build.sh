#!/bin/bash

cd src

nasm -I../../os-code/ hello.asm -o ../bin/hello.app -l ../bin/hello-debug.txt
nasm -I../../os-code/ sysinfo.asm -o ../bin/sysinfo.app -l ../bin/sysinfo-debug.txt
nasm -I../../os-code/ counter.asm -o ../bin/counter.app

gcc -I../../os-code/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc.o helloc.c
gcc -I../../os-code/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o graphics.o graphics.c
gcc -I../../os-code/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o gavare.o gavare.c

gcc -I../../os-code/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o libBareMetal.o \
                    ../../os-code/api/libBareMetal.c

ld -T c.ld -o ../bin/helloc.app helloc.o libBareMetal.o
ld -T c.ld -o ../bin/graphics.app graphics.o
ld -T c.ld -o ../bin/gavare.app gavare.o

cd ..
