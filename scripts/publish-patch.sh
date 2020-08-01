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
    PATCH_DIR=$PATCHES_DIR/patches/$NAME
    call mkdir -p $PATCH_DIR
    call cp -f $VERSION.patch $PATCH_DIR/$VERSION.patch
fi
