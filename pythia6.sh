# a pythia6 recipe based on the one from FairROOT
package: pythia6
version: "%(tag_basename)s"
tag: "428-alice1"
source: https://github.com/alisw/pythia6.git
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
---
#!/bin/sh

cmake ${SOURCEDIR}                              \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}    \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}     \
      -DCMAKE_INSTALL_LIBDIR=lib                \
      -DCMAKE_Fortran_FLAGS="-std=legacy"       \
      -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--allow-multiple-definition"
make ${JOBS+-j$JOBS}
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
module load BASE/1.0
# Our environment
set PYTHIA6_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PYTHIA6_ROOT \$PYTHIA6_ROOT
prepend-path LD_LIBRARY_PATH \$PYTHIA6_ROOT/lib
prepend-path AGILE_GEN_PATH \$PYTHIA6_ROOT
EoF

