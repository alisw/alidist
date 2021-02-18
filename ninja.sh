package: ninja
version: "v1.10.2"
tag: "v1.10.2"
source: https://github.com/ninja-build/ninja
build_requires:
 - CMake
 - alibuild-recipe-tools
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

cmake -Bbuild-cmake -H$SOURCEDIR
cmake --build build-cmake

mkdir -p $INSTALLROOT/bin
cp build-cmake/ninja $INSTALLROOT/bin

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin >> etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
