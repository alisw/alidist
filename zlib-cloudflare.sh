package: zlib-cloudflare
version: "%(tag_basename)s"
tag: gcc.amd64
source: https://github.com/cloudflare/zlib/
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

echo "Building optimized zlib"

cmake ${SOURCEDIR} -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

# Build and install
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEDIR/$PKGNAME"
