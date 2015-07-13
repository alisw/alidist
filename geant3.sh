package: geant3
version: v1-15a
requires:
  - root
source: http://root.cern.ch/git/geant3.git
tag: v1-15a
prepend_path:
  - "LD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
  - "DYLD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
---
#!/bin/sh

cd $SOURCEDIR
make ${JOBS+-j $JOBS}
mkdir -p $INSTALLROOT/include/TGeant3
mkdir -p $INSTALLROOT/lib
cp TGeant3 $INSTALLROOT/include/TGeant3
rsync -av --exclude "*.o" lib/ $INSTALLROOT/lib/
