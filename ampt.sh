package: AMPT
version: "%(tag_basename)s"
tag: "v1.26t7b-v2.26t7b-alice1"
source: https://github.com/alisw/ampt
requires:
  - "GCC-Toolchain:(?!osx)"
  - HepMC
---
#!/bin/bash -e

cmake  $SOURCEDIR                           \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
       ${HEPMC_REVISION:+-DHEPMC_ROOT=$HEPMC_ROOT}

make ${JOBS+-j $JOBS} install

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
module load BASE/1.0 ${HEPMC_REVISION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION}
# Our environment
set AMPT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv AMPT_ROOT \$AMPT_ROOT
prepend-path PATH \$AMPT_ROOT/bin
#prepend-path LD_LIBRARY_PATH \$AMPT_ROOT/lib
EoF
