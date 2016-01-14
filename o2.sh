package: O2
version: master
requires:
  - FairRoot
  - AliRoot
source: https://github.com/AliceO2Group/AliceO2
tag: dev
---
#!/bin/sh
export ROOTSYS=$ROOT_ROOT

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                              \
      -DCMAKE_MODULE_PATH="$SOURCEDIR/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules"  \
      -DFairRoot_DIR=$FAIRROOT_ROOT                                                               \
      -DALICEO2_MODULAR_BUILD=ON                                                                  \
      -DROOTSYS=$ROOTSYS                                                                          \
      ${PYTHIA6_ROOT:+-DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib}                                    \
      ${GEANT3_ROOT:+-DGeant3_DIR=$GEANT3_ROOT}                                                   \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}                                                   \
      -DFAIRROOTPATH=$FAIRROOT_ROOT                                                               \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                                     \
      -DZMQ_DIR=$ZEROMQ_ROOT                                                                      \
      -DZMQ_INCLUDE_DIR=$ZEROMQ_ROOT/include                                                      \
      -DALIROOT=$ALIROOT_ROOT                                                                     \
      ${PYTHIA8_ROOT:+-DPYTHIA8_INCLUDE_DIR=$PYTHIA_ROOT/include}

if [[ $GIT_TAG == master ]]; then
  CONTINUE_ON_ERROR=true
fi
make ${CONTINUE_ON_ERROR+-k} ${JOBS+-j $JOBS}
make ${CONTINUE_ON_ERROR+-k} install
