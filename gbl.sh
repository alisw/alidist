package: GBL
version: "%(tag_basename)s"
tag: "V03-01-04"
source: https://gitlab.desy.de/claus.kleinwort/general-broken-lines.git
requires:
 - Eigen3
 - ROOT
build_requires:
 - CMake
---
#!/bin/bash -ex

rsync -a "$SOURCEDIR"/cpp/ "$BUILDDIR"/
cd "$BUILDDIR" || exit
cmake . -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DEIGEN3_INCLUDE_DIR="$EIGEN3_ROOT/include/eigen3" \
    -DSUPPORT_ROOT=ON
cmake --build . -- ${JOBS:+-j$JOBS}
cmake --install .
