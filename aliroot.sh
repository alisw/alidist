package: aliroot
version: v5-05-Rev-20
requires:
  - root
env:
  ALICE_ROOT: \$INSTALLROOT
source: http://git.cern.ch/pub/AliRoot
tag: v5-05-Rev-20
---
#!/bin/sh
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DCMAKE_SKIP_RPATH=TRUE

make ${JOBS+-j $JOBS}
make install
cp -r test $INSTALLROOT/test
