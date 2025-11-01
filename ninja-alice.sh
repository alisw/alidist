package: ninja-alice
version: "%(tag_basename)s"
tag: "v1.13.1-alice1"
source: https://github.com/alisw/ninja
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "CMake"
  - alibuild-recipe-tools
---
#!/bin/bash
cmake -Bbuild-cmake "$SOURCEDIR"
cmake --build build-cmake ${JOBS:+-j$JOBS}

mkdir -p "$INSTALLROOT"/bin
cp build-cmake/ninja "$INSTALLROOT/bin"

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin >"$INSTALLROOT/etc/modulefiles/$PKGNAME"
