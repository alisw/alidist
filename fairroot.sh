package: FairRoot
version: "%(short_hash)s"
tag: "717dccd866ec07af10db1e021d189e9ff2ce0209"
source: https://github.com/FairRootGroup/FairRoot
requires:
  - generators
  - simulation
  - ROOT
  - boost
  - protobuf
  - DDS
  - FairLogger
  - FairMQ
  - "GCC-Toolchain:(?!osx)"
env:
  VMCWORKDIR: "$FAIRROOT_ROOT/share/fairbase/examples"
  GEOMPATH:   "$FAIRROOT_ROOT/share/fairbase/examples/common/geometry"
  CONFIG_DIR: "$FAIRROOT_ROOT/share/fairbase/examples/common/gconfig"
prepend_path:
  ROOT_INCLUDE_PATH: "$FAIRROOT_ROOT/include"
---
#!/bin/sh

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    MACOSX_RPATH=OFF
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac

[[ $BOOST_ROOT ]] && BOOST_NO_SYSTEM_PATHS=ON || BOOST_NO_SYSTEM_PATHS=OFF

cmake $SOURCEDIR                                                                            \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                             \
      ${MACOSX_RPATH:+-DMACOSX_RPATH=${MACOSX_RPATH}}                                       \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS"                                                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                             \
      -DROOTSYS=$ROOTSYS                                                                    \
      -DROOT_CONFIG_SEARCHPATH=$ROOT_ROOT/bin                                               \
      ${NANOMSG_ROOT:+-DNANOMSG_DIR=$NANOMSG_ROOT}                                          \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib                                               \
      -DGeant3_DIR=$GEANT3_ROOT                                                             \
      -DDISABLE_GO=ON                                                                       \
      -DBUILD_EXAMPLES=OFF                                                                  \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}                                             \
      -DFAIRROOT_MODULAR_BUILD=ON                                                           \
      ${DDS_ROOT:+-DDDS_PATH=$DDS_ROOT}                                                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                               \
      ${BOOST_ROOT:+-DBOOST_INCLUDEDIR=$BOOST_ROOT/include}                                 \
      ${BOOST_ROOT:+-DBOOST_LIBRARYDIR=$BOOST_ROOT/lib}                                     \
      -DBoost_NO_SYSTEM_PATHS=${BOOST_NO_SYSTEM_PATHS}                                      \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                      \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.$SONAME}           \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.$SONAME} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.$SONAME}      \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}              \
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
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0                                                                            \\
            ${FAIRLOGGER_VERSION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION}          \\
            ${FAIRMQ_VERSION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION}                          \\
            ${GEANT3_VERSION:+GEANT3/$GEANT3_VERSION-$GEANT3_REVISION}                          \\
            ${GEANT4_VMC_VERSION:+GEANT4_VMC/$GEANT4_VMC_VERSION-$GEANT4_VMC_REVISION}          \\
            ${PROTOBUF_VERSION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}                  \\
            ${PYTHIA6_VERSION:+pythia6/$PYTHIA6_VERSION-$PYTHIA6_REVISION}                      \\
            ${PYTHIA_VERSION:+pythia/$PYTHIA_VERSION-$PYTHIA_REVISION}                          \\
            ${VGM_VERSION:+vgm/$VGM_VERSION-$VGM_REVISION}                                      \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}                              \\
            ROOT/$ROOT_VERSION-$ROOT_REVISION                                                   \\
            ${ZEROMQ_VERSION:+ZeroMQ/$ZEROMQ_VERSION-$ZEROMQ_REVISION}                          \\
            ${NANOMSG_VERSION:+nanomsg/$NANOMSG_VERSION-$NANOMSG_REVISION}                      \\
            ${DDS_ROOT:+DDS/$DDS_VERSION-$DDS_REVISION}                                         \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv FAIRROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VMCWORKDIR \$::env(FAIRROOT_ROOT)/share/fairbase/examples
setenv GEOMPATH \$::env(VMCWORKDIR)/common/geometry
setenv CONFIG_DIR \$::env(VMCWORKDIR)/common/gconfig
prepend-path PATH \$::env(FAIRROOT_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(FAIRROOT_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(FAIRROOT_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FAIRROOT_ROOT)/lib")
EoF
