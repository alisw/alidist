package: abseil
version: "%(tag_basename)s"
tag: "20230802.1"
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/abseil/abseil-cpp
incremental_recipe: |
  cmake --build . --target install -- -j$JOBS
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
cmake $SOURCEDIR                             \
  -GNinja                                    \
  -DCMAKE_INSTALL_LIBDIR=lib                 \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}    \
  -DBUILD_TESTING=OFF                        \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . --target install -- -j$JOBS

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
