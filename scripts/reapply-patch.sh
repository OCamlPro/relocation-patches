#!/bin/bash

source ../../../env.sh

RED='\033[0;31m'
NC='\033[0m' # No Color

function call {
    echo -e "${RED} $* ${NC}"
    $* || exit 2
}

function call_in {
    input=$1
    shift
    echo -e "${RED} $* < $input ${NC}"
    $* < $input || exit 2
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

if [ -d $NV-reloc ]; then
    call rm -rf $NV-reloc.backup
    call mv $NV-reloc $NV-reloc.backup
fi

cp -r $NV-orig $NV-reloc

if [ -f $VERSION.patch ]; then
    cd $NV-reloc
    call_in ../$VERSION.patch patch -p1
    cd $CURDIR
fi

rm -rf $NV-test
cp -r $NV-reloc $NV-test
