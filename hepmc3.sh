package: HepMC3
version: "%(tag_basename)s"
tag: 3.3.0
source: https://gitlab.cern.ch/hepmc/HepMC3.git
requires:
  - GCC-Toolchain:(?!osx.*)
  - ROOT
build_requires:
  - CMake
prepend_path:
  ROOT_INCLUDE_PATH: "$HEPMC3_ROOT/include"
---
#!/bin/bash -e

cmake  $SOURCEDIR                          \
       -DROOT_DIR=$ROOT_ROOT               \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
       -DCMAKE_INSTALL_LIBDIR=lib          \
       -DHEPMC3_ENABLE_PYTHON=OFF

make ${JOBS+-j $JOBS}
make install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set HEPMC3_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HEPMC3_ROOT \$HEPMC3_ROOT
prepend-path PATH \$HEPMC3_ROOT/bin
prepend-path LD_LIBRARY_PATH \$HEPMC3_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$HEPMC3_ROOT/include
EoF
