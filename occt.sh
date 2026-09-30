package: OCCT
version: "v7.9.3"
tag: V7_9_3
source: https://github.com/Open-Cascade-SAS/OCCT
license: LGPLv2.1
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT   \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

# Build and install
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE

