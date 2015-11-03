package: FairRoot
version: master
source: https://github.com/FairRootGroup/FairRoot
tag: master
requires:
  - pythia6
  - GEANT3
  - GEANT4
  - ZeroMQ
  - boost
  - GCC:slc6.*
---
#!/bin/sh

export ROOTSYS=$ROOT_ROOT

cmake $SOURCEDIR \
      -DCMAKE_CXX_FLAGS="-std=c++11" \
      -DCMAKE_RELEASE_TYPE=RelWithDebInfo \
      -DROOTSYS=$ROOTSYS \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib \
      -DGeant3_DIR=$GEANT3_ROOT \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT} \
      -DFAIRROOT_MODULAR_BUILD=ON \
      -DZMQ_DIR=$ZEROMQ_ROOT \
      -DBOOSTROOT=$BOOST_ROOT \
      -DBOOST_INCLUDEDIR=$BOOST_ROOT/include \
      -DBOOST_LIBRARYDIR=$BOOST_ROOT/lib \
      -DBoost_NO_SYSTEM_PATHS=ON \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j $JOBS}
make install
