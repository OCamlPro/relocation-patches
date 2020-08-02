#!/bin/bash

source ./env.sh

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

NAME=$1
VERSION=$2
NV=$NAME.$VERSION

echo Package $NV

CURDIR=$(pwd)
export OPAMROOT=$CURDIR/root

call mkdir -p work
cd work
call rm -rf $NAME/$VERSION
call mkdir -p $NAME/$VERSION
cd $NAME/$VERSION



call opam source $NV
call mv $NV $NV-orig

call_out OPAM opam show --safe --raw $NV

call ln -sf ../../../scripts/make-patch.sh
call ln -sf ../../../scripts/reapply-patch.sh
call ln -sf ../../../scripts/publish-patch.sh

PATCH=$PATCHES_DIR/patches/$NAME/$VERSION.patch
if [ -f $PATCH ]; then
    echo Found relocation patch !
    call cp $PATCH $VERSION.patch
else
    echo No patch $PATCH
fi

./reapply-patch.sh
