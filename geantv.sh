package: GEANTV
version: "%(tag_basename)s"
tag: master
source: https://gitlab.cern.ch/GeantV/geant.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - VecGeom
  - HepMC3
  - pythia
  - Vc
  - GEANT4
build_requires:
  - CMake
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DUSE_VECGEOM_NAVIGATOR=ON                       \
      -DVecGeom_DIR=$VECGEOM_ROOT/lib/CMake/VecGeom    \
      -DUSE_ROOT=ON                                    \
      -DHepMC_DIR=$HEPMC3_ROOT/cmake/                  \
      -DPYTHIA8_ROOT_DIR=$PYTHIA_ROOT                  \
      -DCMAKE_PREFIX_PATH=$VC_ROOT/lib/cmake/Vc

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
module load BASE/1.0 Pythia/$PYTHIA_VERSION-$PYTHIA_REVISION Vc/$VC_VERSION-$VC_REVISION VecGeom/$VECGEOM_VERSION-$VECGEOM_REVISION GEANT4/$GEANT4_VERSION-$GEANT4_REVISION HepMC3/$HEPMC3_VERSION-$HEPMC3_REVISION
# Our environment
set osname [uname sysname]
set GEANTV_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(GEANTV_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(GEANTV_ROOT)/lib
EoF
