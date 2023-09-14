package: abseil
version: "%(tag_basename)s"
tag: "20220623.1"
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/abseil/abseil-cpp
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

mkdir -p $INSTALLROOT
cmake $SOURCEDIR                             \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}    \
  -DCMAKE_INSTALL_LIBDIR=lib                 \
  -DBUILD_TESTING=OFF                        \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
