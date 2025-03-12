package: ninja-fortran
version: "fortran-%(short_hash)s"
tag: "v1.11.1.g95dee.kitware.jobserver-1"
source: https://github.com/Kitware/ninja
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "CMake"
  - alibuild-recipe-tools
---
#!/bin/bash
cmake -Bbuild-cmake $SOURCEDIR
cmake --build build-cmake

mkdir -p $INSTALLROOT/bin
cp build-cmake/ninja "$INSTALLROOT/bin"

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin >"$INSTALLROOT/etc/modulefiles/$PKGNAME"
