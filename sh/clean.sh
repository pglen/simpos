#!/bin/sh

clean_dir()  {
    echo Cleaning $1
    XWD=$(pwd)
    cd $1
    ./clean.sh
    cd $XWD
}

clean_dir "src/simpos64"
clean_dir "src/os-code"
clean_dir "src/mon-code"
clean_dir "src/app-code"
clean_dir "src/BMFS"

echo Removing generated sys files
rm -rf sys/*
# So tail can see the inode
touch sys/serial.log

