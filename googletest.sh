package: googletest
version: "1.8.0"
source: https://github.com/google/googletest
tag: release-1.8.0
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
---
#!/bin/sh
cmake                                                     \
      ${C_COMPILER:+-DCMAKE_C_COMPILER=$C_COMPILER}       \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER} \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                 \
      $SOURCEDIR

make ${JOBS+-j $JOBS}
make install
