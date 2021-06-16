package: c-ares
version: "v1.17.1"
tag: cares-1_17_1
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
source: https://github.com/c-ares/c-ares
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

cmake $SOURCEDIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j$JOBS} install



MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEDIR/$PKGNAME"
