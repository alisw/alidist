package: O2
version: master
requires:
  - FairRoot
  - AliRoot
  - pythia8
  - pythia6
source: https://github.com/ktf/AliceO2
tag: master
---
#!/bin/sh
export ROOTSYS=$ROOT_ROOT

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_MODULE_PATH="$SOURCEDIR/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules" \
      -DFairRoot_DIR=$FAIRROOT_ROOT \
      -DALICEO2_MODULAR_BUILD=ON \
      -DROOTSYS=$ROOTSYS \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib \
      -DGeant3_DIR=$GEANT3_ROOT \
      -DGeant4_DIR=$GEANT4_ROOT \
      -DFAIRROOTPATH=$FAIRROOT_ROOT \
      -DBOOST_ROOT=$BOOST_ROOT \
      -DZMQ_DIR=$ZEROMQ_ROOT \
      -DZMQ_INCLUDE_DIR=$ZEROMQ_ROOT/include \
      -DALIROOT=$ALIROOT_ROOT \
      -DPYTHIA8_INCLUDE_DIR=$PYTHIA8_ROOT/include

if [[ $GIT_TAG == master ]]; then
  CONTINUE_ON_ERROR=true
fi
make ${CONTINUE_ON_ERROR+-k} ${JOBS+-j $JOBS}
make ${CONTINUE_ON_ERROR+-k} install
