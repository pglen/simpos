#!/bin/bash
# Search the whole project for stuff
find . -name *.asm -exec grep -H "$1" {} \;
find . -name *.inc -exec grep -H "$1" {} \;
find . -name *.c   -exec grep -H "$1" {} \;

