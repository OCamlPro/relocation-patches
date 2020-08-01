#!/bin/bash

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

call opam bin config --disable-create

CURDIR=$(pwd)

export OPAM_BIN_RELOC=true

# move packages from PACKAGES to OK_PACKAGES as soon as they successfully
# compiled. MORE_PACKAGES are packages that are not tested for relocation,
# only that their dependencies are relocatable

OK_PACKAGES=" base-bigarray.base base-threads.base base-unix.base
ocaml.4.07.1 conf-which.1 conf-m4.1 conf-pkg-config.1.1 conf-perl.1
conf-gmp.1 conf-zlib.1 conf-sqlite3.1 conf-mpfr.1 ocaml-config.1
ocaml.4.07.1 ctypes-foreign.0.4.0 seq.base camlidl.1.07
cmdliner.1.0.3"

PACKAGES="ocamlfind.1.8.0 base-bytes.base camlzip.1.07 num.1.2
ppx_tools.5.1+4.06.0 ocamlbuild.0.12.0 zarith.1.7-1 mlgmpidl.1.2.9
ocamlgraph.1.8.8 dune.1.6.3 jbuilder.transition ANSITerminal.0.8.1
ounit.2.0.8 base64.3.1.0 cppo.1.6.5 easy-format.1.3.1
jane-street-headers.v0.11.0 ocaml-compiler-libs.v0.11.0 octavius.1.2.0
ppx_derivers.1.0 re.1.8.0 result.1.3 sexplib0.v0.11.0 spawn.v0.13.0
cppo_ocamlbuild.1.6.0 biniou.1.2.0 parsexp.v0.11.0 yojson.1.4.1
atdgen-runtime.2.0.0 sexplib.v0.11.0 ocaml-migrate-parsetree.1.1.0
topkg.1.0.0 base.v0.11.1 integers.0.2.2 mtime.1.1.0 xmlm.1.3.0
stdio.v0.11.0 typerep.v0.11.0 configurator.v0.11.0 sqlite3.4.4.1
ppx_deriving.4.2.1 ppxlib.0.3.1 ctypes.0.14.0 fieldslib.v0.11.0
ppx_here.v0.11.0 ppx_enumerate.v0.11.1 ppx_let.v0.11.0
ppx_compare.v0.11.1 ppx_optcomp.v0.11.0 ppx_optional.v0.11.0
ppx_inline_test.v0.11.0 ppx_js_style.v0.11.0 ppx_pipebang.v0.11.0
ppx_sexp_conv.v0.11.2 ppx_typerep_conv.v0.11.1 variantslib.v0.11.0
ppx_fields_conv.v0.11.0 ppx_fail.v0.11.0 ppx_hash.v0.11.1
camomile.1.0.1 ppx_bench.v0.11.0 ppx_assert.v0.11.0
ppx_custom_printf.v0.11.0 ppx_sexp_message.v0.11.0
ppx_sexp_value.v0.11.0 ppx_variants_conv.v0.11.1 ppx_base.v0.11.0
bin_prot.v0.11.0 ppx_expect.v0.11.1 ppx_bin_prot.v0.11.1
ppx_jane.v0.11.0 splittable_random.v0.11.0 core_kernel.v0.11.1
menhir.20181113 atd.2.0.0 atdgen.2.0.0 apron.20160125
dune-configurator.1.0.0 gen.0.5.1 ocplib-simplex.0.4 spelll.0.3
stdlib-shims.0.1.0 fmt.0.8.8 psmt2-frontend.0.2 camlp5.8.00~alpha01
aez.0.3 iter.1.2.1 alt-ergo-lib.2.3.2 msat.0.8.2
alt-ergo-parsers.2.3.2 alt-ergo.2.3.2 "

MORE_PACKAGES="why3.1.3.1"

echo $PACKAGES

INITHASH=$(echo $OK_PACKAGES | md5sum | awk '{ print $1 }')

call opam update

call_safe opam switch remove test1 -y
call_safe opam switch remove test2 -y

call opam switch create test1 --empty
if [ -e $CURDIR/test1-init-$INITHASH.tar ] ; then
    cd $OPAMROOT
    call tar xf $CURDIR/test1-init-$INITHASH.tar
    cd $CURDIR
else
    call opam install ${OK_PACKAGES} -b
    cd $OPAMROOT
    call tar cf $CURDIR/test1-init-$INITHASH.tar test1
    cd $CURDIR
fi


call opam switch create test2 --empty
if [ -e $CURDIR/test2-init-$INITHASH.tar ] ; then
    cd $OPAMROOT
    call tar xf $CURDIR/test2-init-$INITHASH.tar
    cd $CURDIR
else
    call opam install ${OK_PACKAGES} -b -y
    cd $OPAMROOT
    call tar cf $CURDIR/test2-init-$INITHASH.tar test2
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
    call rm -f $CURDIR/test1.tar
    cd $OPAMROOT/test1
    call tar cf $CURDIR/test1.tar *
    cd $CURDIR

    echo '<<<<  install package on test2 >>>>>'
    call opam switch test2
    call opam install ${package} -y -b || exit 2
    call rm -f $CURDIR/test2.tar
    cd $OPAMROOT
    call tar cf $CURDIR/test2.tar test2
    cd $CURDIR

    echo '<<<<  swapping switch files from test1 to test2 >>>>>'
    call mv $OPAMROOT/test1 $OPAMROOT/test1.backup
    cd $OPAMROOT/test2
    call rm -rf *
    cd $OPAMROOT/test2;
    call tar xf $CURDIR/test1.tar
    cd $CURDIR

    echo '<<<<  building infer in test2 with files from test1 >>>>>'
    call opam install ${PACKAGES} ${MORE_PACKAGES} -y -b

    echo '<<<<  restoring test2 files >>>>>'
    cd $OPAMROOT
    rm -rf test2
    tar xf $CURDIR/test2.tar test2
    cd $CURDIR
    mv $OPAMROOT/test1.backup  $OPAMROOT/test1
done
