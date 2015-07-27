package: GEANT4_VMC
version: "v3-1-p2"
source: https://github.com/alisw/geant4_vmc
requires:
  - ROOT
  - GEANT4
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
make ${JOBS+-j $JOBS}
make install
