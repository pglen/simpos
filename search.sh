#!/bin/bash
# Search the whole project for stuff
find . -name *.asm -exec grep -H $1 $2 $3 {} \;
find . -name *.c -exec grep -H $1 $2 $3 {} \;

