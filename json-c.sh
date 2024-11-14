package: json-c
version: "v0.17.0"
tag: "json-c-0.17-20230812"
source: https://github.com/json-c/json-c
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      -DBUILD_SHARED_LIBS=OFF                                    \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . --target install ${JOBS:+-- -j$JOBS}

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
