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
  - "GCC-Toolchain:(?!osx|slc5)"
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
