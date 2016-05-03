package: FairRoot
version: master
source: https://github.com/FairRootGroup/FairRoot
tag: master
requires:
  - generators
  - simulation
  - ROOT
  - ZeroMQ
  - nanomsg
  - boost
  - "GCC-Toolchain:(?!osx)"
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
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
  ;;
esac

cmake $SOURCEDIR                                             \
      -DMACOSX_RPATH=OFF                                     \
      -DCMAKE_CXX_FLAGS="-std=c++11"                         \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                      \
      -DROOTSYS=$ROOTSYS                                     \
      -DROOT_CONFIG_SEARCHPATH=$ROOT_ROOT/bin                \
      -DNANOMSG_INCLUDE_DIR=$NANOMSG_ROOT/include            \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib                \
      -DGeant3_DIR=$GEANT3_ROOT                              \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}              \
      -DFAIRROOT_MODULAR_BUILD=ON                            \
      ${ZEROMQ_ROOT:+-DZMQ_DIR=$ZEROMQ_ROOT}                 \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                \
      ${BOOST_ROOT:+-DBOOST_INCLUDEDIR=$BOOST_ROOT/include}  \
      ${BOOST_ROOT:+-DBOOST_LIBRARYDIR=$BOOST_ROOT/lib}      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j $JOBS} install

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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} ROOT/$ROOT_VERSION-$ROOT_REVISION ${ZEROMQ_VERSION:+ZeroMQ/$ZEROMQ_VERSION-$ZEROMQ_REVISION} ${DDS_ROOT:+DDS/$DDS_VERSION-$DDS_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv FAIRROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(FAIRROOT_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FAIRROOT_ROOT)/lib")
EoF
