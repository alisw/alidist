package: AliPhysics
version: v5-06-35-01
requires:
  - AliRoot
source: http://git.cern.ch/pub/AliPhysics
tag: master
env:
  ALICE_PHYSICS: "$ALIPHYSICS_ROOT"
---
#!/bin/bash -e
# TODO: build with -DFASTJET
cmake "$SOURCEDIR" \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DALIEN="$ALIEN_ROOT"/alien \
      -DROOTSYS="$ROOT_ROOT" \
      -DALIROOT="$ALIROOT_ROOT"
make ${JOBS+-j $JOBS}
make install
