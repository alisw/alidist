package: GEANT4_VMC
version: "%(tag_basename)s"
tag: "v6-6-update1-p3"
source: https://github.com/vmc-project/geant4_vmc
requires:
  - ROOT
  - VMC
  - GEANT4
  - vgm
build_requires:
  - CMake
  - ninja
  - "Xcode:(osx.*)"
prepend_path:
  ROOT_INCLUDE_PATH: "$GEANT4_VMC_ROOT/include/g4root:$GEANT4_VMC_ROOT/include/geant4vmc"
env:
  G4VMCINSTALL: "$GEANT4_VMC_ROOT"
---
#!/bin/bash -e
LDFLAGS="$LDFLAGS -L$GEANT4_ROOT/lib"            \
  cmake "$SOURCEDIR"                             \
    -GNinja                                      \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DGeant4VMC_USE_VGM=ON                       \
    -DCMAKE_INSTALL_LIBDIR=lib                   \
    -DGeant4VMC_BUILD_EXAMPLES=OFF               \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS+-j $JOBS} install

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
module load BASE/1.0 ${GEANT4_REVISION:+GEANT4/$GEANT4_VERSION-$GEANT4_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${VMC_REVISION:+VMC/$VMC_VERSION-$VMC_REVISION} vgm/$VGM_VERSION-$VGM_REVISION
# Our environment
set GEANT4_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GEANT4_VMC_ROOT \$GEANT4_VMC_ROOT
setenv G4VMCINSTALL \$GEANT4_VMC_ROOT
setenv USE_VGM 1
prepend-path PATH \$GEANT4_VMC_ROOT/bin
prepend-path ROOT_INCLUDE_PATH \$GEANT4_VMC_ROOT/include/geant4vmc
prepend-path ROOT_INCLUDE_PATH \$GEANT4_VMC_ROOT/include/g4root
prepend-path LD_LIBRARY_PATH \$GEANT4_VMC_ROOT/lib
EoF
