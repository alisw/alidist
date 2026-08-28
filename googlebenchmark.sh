package: googlebenchmark
version: "1.9.5"
tag: v1.9.5
license: Apache-2.0
source: https://github.com/google/benchmark
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake $SOURCEDIR                           \
      -G Ninja                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DBENCHMARK_ENABLE_TESTING=OFF       \
      -DBENCHMARK_ENABLE_GTEST_TESTS=OFF   \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
