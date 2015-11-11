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
make ${JOBS+-j $JOBS} bootstrap-lean
make install

# GCC creates c++, but not cc
ln -nfs gcc "$INSTALLROOT/bin/cc"
rm -rf "$INSTALLROOT/lib/pkg-config"

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
