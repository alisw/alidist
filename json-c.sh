package: json-c
version: "v0.18.0"
tag: "json-c-0.18-20240915"
source: https://github.com/json-c/json-c
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5                         \
      -DBUILD_SHARED_LIBS=OFF                                    \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . --target install ${JOBS:+-- -j$JOBS}

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
