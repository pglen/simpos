#!/bin/sh

saveapp() {

./bmfs disk.img create $1 2
./bmfs disk.img write $1

}

cd src/app-code/bin
cp *.app ../../../sys/
cd ../../../sys/

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

# EOF
