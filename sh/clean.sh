#!/bin/sh

clean_dir()  {
    echo Cleaning $1
    XWD=$(pwd)
    cd $1
    ./clean.sh
    cd $XWD
}

clean_dir "src/Pure64"
clean_dir "src/BareMetal"
clean_dir "src/BareMetal-Monitor"
clean_dir "src/BMFS"

rm -rf sys

