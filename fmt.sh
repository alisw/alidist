package: fmt
version: "%(tag_basename)s"
tag: 10.1.1
source: https://github.com/fmtlib/fmt
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
prepend_path:
  ROOT_INCLUDE_PATH: "$FMT_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -GNinja -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DFMT_TEST=OFF -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=ON

cmake --build . --target install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --lib --cmake > $MODULEFILE
cat << EOF >> $MODULEFILE
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
