package: HepMC3
version: "v3.0.0-git_%(short_hash)s"
tag: d43693ce0e7731e9b787dbd6176cb6245fd770b3
source: https://gitlab.cern.ch/hepmc/HepMC3.git
requires:
  - GCC-Toolchain:(?!osx.*)
  - ROOT
build_requires:
  - CMake
---
#!/bin/bash -e

cmake  $SOURCEDIR                          \
       -DROOT_DIR=$ROOT_ROOT               \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
       -DCMAKE_INSTALL_LIBDIR=lib

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
setenv HEPMC3_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(HEPMC3_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(HEPMC3_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(HEPMC3_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(HEPMC3_ROOT)/lib")
EoF
