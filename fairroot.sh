package: FairRoot
version: "v18.8.0-beta"
tag: v18.8_patches
source: https://github.com/FairRootGroup/FairRoot
requires:
  - generators
  - simulation
  - ROOT
  - VMC
  - FairLogger
  - "GCC-Toolchain:(?!osx)"
env:
  VMCWORKDIR: "$FAIRROOT_ROOT/share/fairbase/examples"
  GEOMPATH:   "$FAIRROOT_ROOT/share/fairbase/examples/common/geometry"
  CONFIG_DIR: "$FAIRROOT_ROOT/share/fairbase/examples/common/gconfig"
prepend_path:
  ROOT_INCLUDE_PATH: "$FAIRROOT_ROOT/include"
---
# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    MACOSX_RPATH=OFF
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac

cmake $SOURCEDIR                                                                            \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                             \
      ${MACOSX_RPATH:+-DMACOSX_RPATH=${MACOSX_RPATH}}                                       \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS"                                                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                             \
      -DROOTSYS=$ROOTSYS                                                                    \
      -DROOT_CONFIG_SEARCHPATH=$ROOT_ROOT/bin                                               \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib                                               \
      -DGeant3_DIR=$GEANT3_ROOT                                                             \
      -DBUILD_MBS=OFF                                                                       \
      -DBUILD_EXAMPLES=OFF                                                                  \
      -DBUILD_BASEMQ=OFF                                                                    \
      -DBUILD_PROOF_SUPPORT=OFF                                                             \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}                                             \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                      \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
      -DCMAKE_DISABLE_FIND_PACKAGE_yaml-cpp=ON                                              \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                    \
      -DCMAKE_INSTALL_LIBDIR=lib                                                            \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- -j$JOBS install

# Work around hardcoded paths in PCM
for DIR in source sink field event sim steer; do
  ln -nfs ../include $INSTALLROOT/include/$DIR
done

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" <<EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
