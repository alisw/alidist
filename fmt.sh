package: fmt
version: "%(tag_basename)s"
tag: 7.1.0
source: https://github.com/fmtlib/fmt
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$FMT_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DFMT_TEST=OFF -DCMAKE_INSTALL_LIBDIR=lib

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --root-env > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
