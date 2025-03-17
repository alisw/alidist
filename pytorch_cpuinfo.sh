package: pytorch_cpuinfo
version: "alice1"
tag: b73ae6c
source: https://github.com/pytorch/cpuinfo
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
  cmake "$SOURCEDIR"                             \
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DJSON_BuildTests=OFF                          \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
