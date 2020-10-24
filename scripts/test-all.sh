#!/bin/bash

SCRIPTDIR=$(dirname $(readlink $0))
echo SCRIPTDIR: ${SCRIPTDIR}

CURDIR=$(pwd)
WORKDIR=${CURDIR}/_tmp

mkdir -p ${WORKDIR}
export OPAMROOT=${WORKDIR}/root

source ${SCRIPTDIR}/setup-opambin.sh

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

call opam bin config --enable-create

export OPAM_BIN_RELOC=true

# move packages from PACKAGES to OK_PACKAGES as soon as they successfully
# compiled. MORE_PACKAGES are packages that are not tested for relocation,
# only that their dependencies are relocatable

OK_PACKAGES=$(cat base-packages.txt)
PACKAGES=$(cat test-packages.txt)

MORE_PACKAGES=""

echo $PACKAGES

INITHASH=$(echo $OK_PACKAGES | md5sum | awk '{ print $1 }')

call opam update

call_safe opam switch remove test1 -y
call_safe opam switch remove test2 -y

call opam switch create test1 --empty
if [ -e ${WORKDIR}/test1-init-$INITHASH.tar ] ; then
    cd $OPAMROOT
    call tar xf ${WORKDIR}/test1-init-$INITHASH.tar
    cd $CURDIR
else
    call opam install ${OK_PACKAGES} -b -y
    cd $OPAMROOT
    call tar cf ${WORKDIR}/test1-init-$INITHASH.tar test1
    cd $CURDIR
fi

call opam switch set-base ${OK_PACKAGES}
call opam bin config --disable-create

call opam switch create test2 --empty
if [ -e ${WORKDIR}/test2-init-$INITHASH.tar ] ; then
    cd $OPAMROOT
    call tar xf ${WORKDIR}/test2-init-$INITHASH.tar
    cd $CURDIR
else
    call opam install ${OK_PACKAGES} -b -y
    cd $OPAMROOT
    call tar cf ${WORKDIR}/test2-init-$INITHASH.tar test2
    cd $CURDIR
fi

call rm -rf $OPAMROOT/test1.backup


for package in ${PACKAGES}; do
    echo ' ============================================================= '
    echo
    echo
    echo
    echo Trying package:                 ${package}
    date +%H:%M:%S
    echo
    echo
    echo
    echo ' ============================================================= '

    echo '<<<<  install package on test1 >>>>>'
    call opam switch test1
    call opam install ${package} -y -b || exit 2
    call rm -f ${WORKDIR}/test1.tar
    cd $OPAMROOT/test1
    call tar cf ${WORKDIR}/test1.tar *
    cd $CURDIR

    echo '<<<<  install package on test2 >>>>>'
    call opam switch test2
    call opam install ${package} -y -b || exit 2
    call rm -f ${WORKDIR}/test2.tar
    cd $OPAMROOT
    call tar cf ${WORKDIR}/test2.tar test2
    cd $CURDIR

    echo '<<<<  swapping switch files from test1 to test2 >>>>>'
    call mv $OPAMROOT/test1 $OPAMROOT/test1.backup
    cd $OPAMROOT/test2
    call rm -rf *
    cd $OPAMROOT/test2;
    call tar xf ${WORKDIR}/test1.tar
    cd $CURDIR

    echo '<<<<  building final in test2 with files from test1 >>>>>'
    call opam install ${PACKAGES} ${MORE_PACKAGES} -y -b

    echo '<<<<  restoring test2 files >>>>>'
    cd $OPAMROOT
    rm -rf test2
    tar xf ${WORKDIR}/test2.tar test2
    cd $CURDIR
    mv $OPAMROOT/test1.backup  $OPAMROOT/test1
done
