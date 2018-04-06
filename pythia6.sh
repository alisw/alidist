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

cmake ${SOURCEDIR}                           \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}  \
      -DCMAKE_INSTALL_LIBDIR=lib
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
setenv PYTHIA6_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(PYTHIA6_ROOT)/lib
prepend-path AGILE_GEN_PATH \$::env(PYTHIA6_ROOT)
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(PYTHIA6_ROOT)/lib")
EoF

