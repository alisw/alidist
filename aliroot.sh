package: aliroot
version: v5-06-28
requires:
  - root
env:
  ALICE_ROOT: \$INSTALLROOT
source: http://git.cern.ch/pub/AliRoot
tag: master
---
#!/bin/sh
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_ROOT/alien \
      -DCMAKE_SKIP_RPATH=TRUE

if [[ $GIT_TAG == master ]]; then
  CONTINUE_ON_ERROR=true
fi
make ${CONTINUE_ON_ERROR+-k} ${JOBS+-j $JOBS}
make install
cp -r test $INSTALLROOT/test
