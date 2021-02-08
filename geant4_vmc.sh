package: GEANT4_VMC
version: "%(tag_basename)s"
tag: "v5-3"
source: https://github.com/vmc-project/geant4_vmc
requires:
  - ROOT
  - GEANT4
  - vgm
build_requires:
  - CMake
  - "Xcode:(osx.*)"
prepend_path:
  ROOT_INCLUDE_PATH: "$GEANT4_VMC_ROOT/include/g4root:$GEANT4_VMC_ROOT/include/geant4vmc:$GEANT4_VMC_ROOT/include/mtroot"
env:
  G4VMCINSTALL: "$GEANT4_VMC_ROOT"
---
#!/bin/bash -e
LDFLAGS="$LDFLAGS -L$GEANT4_ROOT/lib"            \
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DGeant4VMC_USE_VGM=ON                       \
    -DCMAKE_INSTALL_LIBDIR=lib                   \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

make ${JOBS+-j $JOBS} install
G4VMC_SHARE=$(cd "$INSTALLROOT/share"; echo Geant4VMC-* | cut -d' ' -f1)
ln -nfs "$G4VMC_SHARE/examples" "$INSTALLROOT/share/examples"

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
module load BASE/1.0 ${GEANT4_REVISION:+GEANT4/$GEANT4_VERSION-$GEANT4_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} vgm/$VGM_VERSION-$VGM_REVISION
# Our environment
set GEANT4_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GEANT4_VMC_ROOT \$GEANT4_VMC_ROOT
setenv G4VMCINSTALL \$GEANT4_VMC_ROOT
prepend-path PATH \$GEANT4_VMC_ROOT/bin
prepend-path ROOT_INCLUDE_PATH \$GEANT4_VMC_ROOT/include/mtroot
prepend-path ROOT_INCLUDE_PATH \$GEANT4_VMC_ROOT/include/geant4vmc
prepend-path ROOT_INCLUDE_PATH \$GEANT4_VMC_ROOT/include/g4root
prepend-path LD_LIBRARY_PATH \$GEANT4_VMC_ROOT/lib
EoF
