package: googlebenchmark
version: "1.3.0"
tag: v1.3.0
source: https://github.com/google/benchmark
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
---
#!/bin/sh
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}
make ${JOBS+-j $JOBS}
make install
