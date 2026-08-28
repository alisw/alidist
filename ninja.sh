package: ninja
version: "fortran-%(short_hash)s"
tag: "v1.11.1.g95dee.kitware.jobserver-1"
license: Apache-2.0
source: https://github.com/Kitware/ninja
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "CMake"
  - alibuild-recipe-tools
prefer_system: .*
prefer_system_check: |
  type ninja
---
#!/bin/bash
cmake -Bbuild-cmake "$SOURCEDIR"
cmake --build build-cmake ${JOBS:+-j$JOBS}

mkdir -p "$INSTALLROOT"/bin
cp build-cmake/ninja "$INSTALLROOT/bin"

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin >"$INSTALLROOT/etc/modulefiles/$PKGNAME"
