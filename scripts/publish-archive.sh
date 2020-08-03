#!/bin/sh

rm -f relocation-patches.tar*
git archive master -o relocation-patches.tar
gzip -n relocation-patches.tar

scp relocation-patches.tar.gz http.new:/var/www/www.typerex.org/opam-bin/relocation-patches.tar.gz
