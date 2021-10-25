#!/bin/bash

if [ $# -lt 2 ] ; then
    echo "Usage: cmpdate.sh [-v] reffile newfile [ newfile2 ...] "
    exit 0
fi

# The One option
VERB=0
if [ $1 == "-v" ] ; then
    shift
    VERB=1
fi

if [ -e $1 ] ; then
    FFF=$(stat -c %Y $1)
else
    echo Ref file must exist.
    exit 2
fi
ORG=$1
shift
RET=0
for var in "$@"
do
    #echo processing $var
    if [ -e $var ] ; then
        SSS=$(stat -c %Y $var)
    else
        SSS=0
    fi
    #echo $FFF $SSS

    # Check date
    if [ $FFF -gt $SSS ] ; then
        if [ $VERB -ne 0 ] ; then
            echo "Later   " $ORG - $var
        fi
        RET=1
    else
        if [ $VERB -ne 0 ] ; then
            echo "Earlier " $ORG - $var
        fi
        # No change
    fi
done
exit $RET
# EOF
