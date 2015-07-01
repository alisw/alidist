package: geant3
version: v2-0
requires:
  - root
source: http://root.cern.ch/git/geant3.git
tag: v2-0
prepend_path:
  - "LD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
  - "DYLD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
---
#!/bin/sh

mkdir obj
cd obj
cmake $BUILDDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
        -DROOTSYS=$ROOT_ROOT \
        -DCMAKE_SKIP_RPATH=TRUE
make ${JOBS+-j $JOBS}
make install
