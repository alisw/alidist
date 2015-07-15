package: AliRoot
version: v5-05-Rev-20
requires:
  - ROOT
env:
  ALICE_ROOT: \$INSTALLROOT
source: http://git.cern.ch/pub/AliRoot
tag: v5-05-Rev-20
---
#!/bin/sh
export ALICE_ROOT=$INSTALLROOT
export ROOTSYS=$ROOT_ROOT
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DCMAKE_SKIP_RPATH=TRUE

make ${JOBS+-j $JOBS}
make install
cp -r $SOURCEDIR/test $INSTALLROOT/test
