package: GBL
version: "%(tag_basename)s"
tag: "V04-00-06"
source: https://github.com/GeneralBrokenLines/GeneralBrokenLines.git
requires:
  - Eigen3
  - ROOT
  - Mille
license: GPL-3.0
build_requires:
  - alibuild-recipe-tools
  - CMake
---
#!/bin/bash -e

cmake -S "${SOURCEDIR}/cpp/" -B "$BUILDDIR"            \
    -DCMAKE_CXX_STANDARD="$(root-config --cxxstandard)" \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON                   \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"             \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"              \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5                 \
    -DEIGEN3_INCLUDE_DIR="$EIGEN3_ROOT/include/eigen3" \
    -DMille_DIR="$MILLE_ROOT/cmake"                   \
    -DCMAKE_REQUIRE_FIND_PACKAGE_Mille=ON             \
    -DSUPPORT_ROOT=ON
cmake --build . -- ${JOBS:+-j$JOBS}
cmake --install .

mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR" && rsync -a --delete etc/modulefiles/ "$MODULEDIR"
