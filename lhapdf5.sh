package: lhapdf5
version: "%(tag_basename)s"
tag: alice/v5.9.1
source: https://github.com/alisw/LHAPDF
env:
  LHAPATH: "$LHAPDF5_ROOT/share/lhapdf"
requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -ex

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS} all
make install

PDFSETS="cteq6l cteq6ll CT10 CT10nlo MSTW2008nnlo EPS09LOR_208 EPS09NLOR_208"
pushd $INSTALLROOT/share/lhapdf
  $INSTALLROOT/bin/lhapdf-getdata $PDFSETS
  # Check if PDF sets were really installed
  for P in $PDFSETS; do
    ls ${P}*
  done
popd

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv LHAPDF5_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPATH \$::env(LHAPDF5_ROOT)/share/lhapdf
prepend-path PATH $::env(LHAPDF5_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LHAPDF5_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(LHAPDF5_ROOT)/lib")
EoF
