package: re2
version: "2019-09-01"
source: https://github.com/google/re2
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
 - alibuild-recipe-tools
---
#!/bin/sh
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DCMAKE_INSTALL_LIBDIR=lib

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEDIR/$PKGNAME"
