package: googletest
version: "1.8.0"
tag: release-1.8.0
source: https://github.com/google/googletest
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
---
#!/bin/sh
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
