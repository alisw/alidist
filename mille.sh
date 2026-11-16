package: Mille
version: "%(tag_basename)s"
tag: V01-01-02
source: https://github.com/millepede-project/mille.git
requires:
  - ROOT
  - zlib
license: LGPL-2.0
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
  - CMake
---
#!/bin/bash -e

cmake -S "$SOURCEDIR" -B "$BUILDDIR"                    \
    -DCMAKE_CXX_COMPILER="${CXX:-g++}"                  \
    -DCMAKE_Fortran_COMPILER="${FC:-gfortran}"          \
    -DCMAKE_CXX_STANDARD="$(root-config --cxxstandard)" \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON                    \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"              \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"               \
    -DSUPPORT_ROOT=ON                                   \
    -DSUPPORT_ZLIB=ON                                   \
    -DBUILD_TESTS=OFF
cmake --build . -- ${JOBS:+-j$JOBS}
cmake --install .

mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR" && rsync -a --delete etc/modulefiles/ "$MODULEDIR"
