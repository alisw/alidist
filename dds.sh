package: DDS
version: master
source: https://github.com/FairRootGroup/DDS
requires:
  - boost
  - CMake
tag: master
---
#!/bin/sh

case $ARCHITECTURE in
  osx*) BOOST_ROOT=$(brew --prefix boost) ;;
esac

cmake $SOURCEDIR                               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT      \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}

make ${JOBS+-j $JOBS}
make install
