package: geant3_vmc-examples
version: "1"
requires:
  - ROOT
  - GEANT4_VMC
  - GEANT3
  - pythia6
build_requires:
  - CMake
---

case $ARCHITECTURE in
  osx*)
    LDSUFFIX="dylib"
  ;;
  *)
    LDSUFFIX="so"
  ;;
esac

Geant4VMC_DIR=`echo $GEANT4_VMC_ROOT/lib/Geant4VMC-*`
Geant3_DIR=`echo ${GEANT3_ROOT}/lib64/Geant3-*`

cmake -DVMC_WITH_Geant3=ON                                          \
      -DVMC_WITH_Geant4=OFF                                         \
      -DGeant3_DIR=$Geant3_DIR                                      \
      -DPythia6_LIBRARY=${PYTHIA6_ROOT}/lib/libPythia6.${LDSUFFIX}  \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}                        \
      -DCMAKE_MODULE_PATH=${GEANT4_VMC_ROOT}/                       \
      -DGeant4VMC_DIR=${Geant4VMC_DIR}                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      ${GEANT4_VMC_ROOT}/share/examples

# make them
make ${JOBS+-j $JOBS} -i
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
module load BASE/1.0 ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} GEANT4_VMC/$GEANT4_VMC_VERSION-$GEANT4_VMC_REVISION GEANT3/$GEANT3_VERSION-$GEANT3_REVISION PYTHIA6/$PYTHIA6_VERSION-$PYTHIA6_REVISION
EoF

