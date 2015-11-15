package: GCC
version: "%(tag_basename)s"
source: https://github.com/alisw/gcc
tag: alice/v4.9.3
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_ROOT/lib64"
  "DYLD_LIBRARY_PATH": "$GCC_ROOT/lib64"
build_requires:
  - autotools
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*) EXTRA_LANGS=',objc,obj-c++' ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./

for EXT in mpfr gmp mpc isl cloog; do
  pushd $EXT
    autoreconf -ivf
  popd
done

./configure --prefix="$INSTALLROOT" \
            --enable-languages="c,c++,fortran${EXTRA_LANGS}" \
            --disable-multilib
# bootstrap-lean saves some space when compiling
make ${JOBS+-j $JOBS} bootstrap-lean
make install

# GCC creates c++, but not cc
ln -nfs gcc "$INSTALLROOT/bin/cc"
rm -rf "$INSTALLROOT/lib/pkg-config"

# GCC needs to "fix" some system header files according to its taste. "Fixed"
# headers are needed for GCC compilation and will override system's ones on the
# destination platform. This will cause a GCC built with, e.g., SLC5 not to be
# able to work when running from, e.g., SLC6. To avoid this we remove the
# "fixed" headers assuming that the ones on the system are OK. This is done by
# nearly all major Linux distributions. Here we are using Gentoo's technique.
#
# See:
# http://ewontfix.com/12/
# https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/eclass/toolchain.eclass?view=markup&sortby=log#l1524
INCLUDE_FIXED=$(find "$INSTALLROOT" -type d -name include-fixed | head -n1)
[[ "$INCLUDE_FIXED" != '' ]]
while read INC; do
  grep -q 'It has been auto-edited by fixincludes from' $INC && rm -f $INC
done < <(find "$INCLUDE_FIXED" -name '*.h')

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv GCC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GCC_ROOT)/lib
prepend-path LD_LIBRARY_PATH \$::env(GCC_ROOT)/lib64
prepend-path PATH \$::env(GCC_ROOT)/bin
EoF
