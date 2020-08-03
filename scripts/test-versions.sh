#!/bin/bash

CURDIR=$(pwd)
export OPAMROOT=$CURDIR/root3
source ./scripts/setup-opambin.sh

RED='\033[0;31m'
NC='\033[0m' # No Color

function call {
    echo -e "${RED} $* ${NC}"
    $* || exit 2
}

function call_safe {
    echo -e "${RED} $* ${NC}"
    $*
}

export OPAM_BIN_RELOC=true


PACKAGE="$1"
VERSION="$2"

if [ "X$PACKAGE" == "X" ]; then
    echo You must specify the package in argument
    exit 2
fi

VERSIONS=$(cd $OPAM_REPO/packages/$PACKAGE; ls -d $PACKAGE.$VERSION*)

call_safe opam switch create tester --empty -y

echo $VERSIONS
echo $PACKAGE

call opam bin clean log

for version in $VERSIONS; do

    echo -e "${RED} call opam install $version -y ${NC}"
    opam install $version -y -b &> $version.log ||
        echo Error with $version
    echo -e "${RED} call opam install $version -y ${NC}"
    opam install $version -y -b &> $version.log ||
        echo Error with $version
    mv $OPAMROOT/plugins/opam-bin/opam-bin.log $version.binlog
done
