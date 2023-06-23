package: lhapdf5
version: "%(tag_basename)s"
tag: v5.9.1-alice3
source: https://github.com/alisw/LHAPDF
env:
  LHAPATH: "$LHAPDF5_ROOT/share/lhapdf"
requires:
  - "GCC-Toolchain:(?!osx)"
  - Python-modules
build_requires:
  - curl
---
#!/bin/bash -ex

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT FCFLAGS="$FCFLAGS -std=legacy"

make ${JOBS+-j $JOBS} all
make install

PDFSETS="cteq6lg CT10 CT10nlo MSTW2008nnlo_mcrange EPS09LOR_208 EPS09NLOR_208"
pushd $INSTALLROOT/share/lhapdf
  PDFREPO=https://lhapdf.hepforge.org/downloads?f=pdfsets/5.9.1/
  # Check if PDF sets were really installed
  for P in $PDFSETS; do
    PDFFILE=$(printf "%s.LHgrid" $P)
    PDFSOURCE=$(printf "%s/%s" $PDFREPO $PDFFILE)
    curl -L $PDFSOURCE --output $PDFFILE
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${PYTHON_MODULES_ROOT:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
# Our environment
set LHAPDF5_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPDF5_ROOT \$LHAPDF5_ROOT
setenv LHAPATH \$::env(LHAPDF5_ROOT)/share/lhapdf
prepend-path PATH \$LHAPDF5_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LHAPDF5_ROOT/lib
EoF
