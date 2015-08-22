package: AliRoot
version: "%(short_hash)s"
requires:
  - ROOT
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot 
tag: master
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_RUNTIME_ROOT \
      -DOCDB_INSTALL=PLACEHOLDER

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} || true
  make -k install || true
else
  make ${JOBS+-j $JOBS}
  make install
fi
cp -r $SOURCEDIR/test $INSTALLROOT/test
