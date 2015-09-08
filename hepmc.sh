package: HepMC
version: "v2.06.09"
source: https://github.com/alisw/hepmc
requires:
  - CMake
---
#!/bin/bash -e

cmake  $SOURCEDIR \
       -Dmomentum=GEV \
       -Dlength=MM \
       -Dbuild_docs:BOOL=OFF \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

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
module load BASE/1.0 CMake/$CMAKE_VERSION-$CMAKE_REVISION
# Our environment
setenv HEPMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(HEPMC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(HEPMC_ROOT)/lib
EoF
