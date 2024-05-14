package: Eigen3
version: 3.4.0
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
source: https://gitlab.com/libeigen/eigen.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install
