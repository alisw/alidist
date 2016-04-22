package: DDS
version: master
source: https://github.com/FairRootGroup/DDS
requires:
  - boost
build_requires:
  - CMake
tag: 99672a0a7770c9230d9fd088d18e04e052dccd10
---
#!/bin/sh

case $ARCHITECTURE in
  osx*) BOOST_ROOT=$(brew --prefix boost) ;;
esac

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT}                  \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include}

make ${JOBS+-j $JOBS} wn_bin; make ${JOBS+-j $JOBS} install
