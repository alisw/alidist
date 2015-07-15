package: fairroot
version: master
source: https://github.com/FairRootGroup/FairRoot
tag: master
requires:
  - root
---
#!/bin/sh

export ROOTSYS=$ROOT_ROOT

cmake $SOURCEDIR \
      -DROOTSYS=$ROOTSYS \
      -DFAIRROOT_MODULAR_BUILD=ON \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS+-j $JOBS}
make install
