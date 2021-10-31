#!/bin/bash

if [ $# -lt 2 ] ; then
    echo "Usage: cmpdate.sh [-v] targetfile srcfile [ srcfile2 ...] "
    echo "Setting exit code based on file date relation"
    exit 0
fi

# Option to show the test if files are earliew
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
    echo $FFF $SSS

    # Check date
    if [ $FFF -lt $SSS ] ; then
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

if [ $VERB -ne 0 ] ; then
    echo "Ret Code " $RET
fi

exit $RET
# EOF
