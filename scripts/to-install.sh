#!/bin/bash


CURDIR=$(pwd)
export OPAMROOT=$CURDIR/root2
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

source ./env.sh


opam init --bare default
call_safe opam switch create empty --empty -y

COMMON="$(cat pre-install.txt)"

rm -rf solutions
mkdir -p solutions
for package in $(cat to-install.txt); do
  echo opam install ${COMMON} ${package} --show-actions
  opam install ${COMMON} ${package} --show-actions > /tmp/solution || exit 2
  awk '{ print $3 " " $4 }' < /tmp/solution | grep -v 'actions would' | grep -v '====' > solutions/$package
done

cat solutions/* | sort | uniq > solution-max.txt
opam install $(cat solution-max.txt) --show-actions > /tmp/solution || exit 2
awk '{ print $3 " " $4 }' < /tmp/solution | grep -v 'actions would' | grep -v '====' > solution.new
