package: GEANT4_VMC
version: "%(tag_basename)s%(defaults_upper)s"
tag: "v3-2-p1"
source: https://github.com/alisw/geant4_vmc
requires:
  - ROOT
  - GEANT4
  - VGM
build_requires:
  - CMake
env:
  G4VMCINSTALL: "$GEANT4_VMC_ROOT"
prepend_path:
  LD_LIBRARY_PATH: "$GEANT4_VMC_ROOT/lib64"
---
#!/bin/bash -e
cmake "$SOURCEDIR"                             \
  -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -DGeant4VMC_USE_VGM=ON                       \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"

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
module load BASE/1.0 GEANT4/$GEANT4_VERSION-$GEANT4_REVISION ROOT/$ROOT_VERSION-$ROOT_REVISION VGM/$VGM_VERSION-$VGM-REVISION
# Our environment
setenv GEANT4_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv G4VMCINSTALL \$::env(GEANT4_VMC_ROOT)
prepend-path PATH \$::env(GEANT4_VMC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(GEANT4_VMC_ROOT)/lib64
EoF
