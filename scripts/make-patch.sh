#!/bin/bash

source ../../../env.sh

RED='\033[0;31m'
NC='\033[0m' # No Color

function call {
    echo -e "${RED} $* ${NC}"
    $* || exit 2
}

function call_out {
    output=$1
    shift
    echo -e "${RED} $* > $output ${NC}"
    $* > $output || exit 2
}

function call_safe {
    echo -e "${RED} $* ${NC}"
    $*
}

CURDIR=$(pwd)

VERSION=$(basename $CURDIR)
NAME=$(basename $(dirname $CURDIR))

NV=$NAME.$VERSION
echo Package $NV

if [ -f $VERSION.patch ]; then
    call_safe mv -f $VERSION.patch.4 $VERSION.patch.5
    call_safe mv -f $VERSION.patch.3 $VERSION.patch.4
    call_safe mv -f $VERSION.patch.2 $VERSION.patch.3
    call_safe mv -f $VERSION.patch.1 $VERSION.patch.2
    call_safe mv -f $VERSION.patch $VERSION.patch.1
fi

echo -e "${RED} diff -r -u -N -x '*~' -x '*.orig' -x '*.rej' $NV-orig $NV-reloc > $VERSION.patch ${NC}"
diff -r -u -N -x '*~' -x '*.orig' -x '*.rej' $NV-orig $NV-reloc > $VERSION.patch
