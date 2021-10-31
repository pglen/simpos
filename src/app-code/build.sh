#!/bin/bash

cd src

nasm -I../../common/ hello.asm -o ../bin/hello.app -l ../bin/hello-debug.txt
nasm -I../../common/ sysinfo.asm -o ../bin/sysinfo.app -l ../bin/sysinfo-debug.txt
nasm -I../../common/ counter.asm -o ../bin/counter.app

gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc.o helloc.c
gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o graphics.o graphics.c
gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o gavare.o gavare.c

gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc2.o hello2.c
gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc3.o hello3.c
gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc4.o hello4.c
gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc5.o hello5.c

gcc -I../../common/ -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o libBareMetal.o \
                    ../../common/libsimpos.c

ld -T c.ld -o ../bin/helloc.app helloc.o libBareMetal.o
ld -T c.ld -o ../bin/helloc2.app helloc2.o libBareMetal.o
ld -T c.ld -o ../bin/helloc3.app helloc3.o libBareMetal.o
ld -T c.ld -o ../bin/helloc4.app helloc4.o libBareMetal.o
ld -T c.ld -o ../bin/helloc5.app helloc5.o libBareMetal.o

ld -T c.ld -o ../bin/graphics.app graphics.o
ld -T c.ld -o ../bin/gavare.app gavare.o

cd ..
