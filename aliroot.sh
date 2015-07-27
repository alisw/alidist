package: AliRoot
version: v5-05-Rev-22c-p1
requires:
  - ROOT
env:
  ALICE_ROOT: \$INSTALLROOT
source: http://git.cern.ch/pub/AliRoot
tag: master
---
#!/bin/sh
cmake $SOURCEDIR \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_ROOT/alien

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} || true
  make -k install || true
else
  make ${JOBS+-j $JOBS}
  make install
fi
cp -r $SOURCEDIR/test $INSTALLROOT/test
