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
---
#!/bin/sh

export ROOTSYS=$ROOT_ROOT

cmake $SOURCEDIR \
      -DROOTSYS=$ROOTSYS \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib \
      -DGeant3_DIR=$GEANT3_ROOT \
      -DGeant4_DIR=$GEANT4_ROOT \
      -DFAIRROOT_MODULAR_BUILD=ON \
      -DZMQ_DIR=$ZEROMQ_ROOT \
      -DBOOST_ROOT=$BOOST_ROOT \
      -DBOOST_INCLUDE_DIR=$BOOST_INCLUDE_DIR \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS+-j $JOBS}
make install
