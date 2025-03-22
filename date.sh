package: date
version: "v3.0.3"
tag: v3.0.3
source: https://github.com/HowardHinnant/date
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
