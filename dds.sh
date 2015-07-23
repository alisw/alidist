package: DDS
version: master
source: https://github.com/FairRootGroup/DDS
requires:
  - boost
tag: master
---
#!/bin/sh

cmake $SOURCEDIR \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS+-j $JOBS}
make install
