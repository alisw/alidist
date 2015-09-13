package: GEANT4_VMC
version: "v3-2"
source: https://github.com/alisw/geant4_vmc
requires:
  - CMake
  - ROOT
  - GEANT4
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
make ${JOBS+-j $JOBS}
make install
