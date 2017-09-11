package: vgm
version: "%(tag_basename)s%(defaults_upper)s"
tag: "4.3-alice1"
source: https://github.com/alisw/vgm.git
requires:
  - ROOT
  - GEANT4
build_requires:
  - CMake
---
#!/bin/bash -e
cmake                                                 \
  ${C_COMPILER:+-DCMAKE_C_COMPILER=$C_COMPILER}       \
  ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER} \
  -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}        \
  -DCMAKE_INSTALL_LIBDIR="lib"                        \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"               \
  "$SOURCEDIR"

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
module load BASE/1.0 GEANT4/$GEANT4_VERSION-$GEANT4_REVISION ROOT/$ROOT_VERSION-$ROOT_REVISION
# Our environment
setenv VGM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(VGM_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(VGM_ROOT)/lib")
EoF
