package: O2
version: master
requires:
  - FairRoot
  - AliRoot
source: https://github.com/AliceO2Group/AliceO2
tag: master
---
#!/bin/sh
export FAIRROOTPATH=$FAIRROOT_ROOT
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DALICEO2_MODULAR_BUILD=ON \
      -DROOTSYS=$ROOTSYS \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib \
      -DGeant3_DIR=$GEANT3_ROOT \
      -DGeant4_DIR=$GEANT4_ROOT \
      -DFAIRROOTPATH=$FAIRROOT_ROOT \
      -DBOOST_ROOT=$BOOST_ROOT \
      -DBOOST_INCLUDE_DIR=$BOOST_INCLUDE_DIR \
      -DZMQ_DIR=$ZEROMQ_ROOT \
      -DALIROOT=$ALIROOT_ROOT

if [[ $GIT_TAG == master ]]; then
  CONTINUE_ON_ERROR=true
fi
make ${CONTINUE_ON_ERROR+-k} ${JOBS+-j $JOBS}
make install
