#!/bin/bash

# ./scripts/test-versions.sh ocaml-base-compiler 4.07.1
#    will test this version
#
# ./scripts/test-versions.sh ocaml-base-compiler
#    will test all versions

source ./env.sh

RED='\033[0;31m'
NC='\033[0m' # No Color

function call {
    echo -e "${RED} $* ${NC}"
    $* || exit 2
}

CURDIR=$(pwd)

echo OPAMROOT=$OPAMROOT

call opam init --bare -n default $OPAM_REPO
call opam remote add --set-default --all default file://$OPAM_REPO

rm -rf $OPAMROOT/download-cache
ln -sf $HOME/.opam/download-cache $OPAMROOT/download-cache

call $OPAMBIN_SRCDIR/opam-bin config --patches-url file://$PATCHES_DIR
call $OPAMBIN_SRCDIR/opam-bin install

cd $CURDIR
