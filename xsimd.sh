package: xsimd
version: "14.0.0"
tag: 14.0.0
source: https://github.com/xtensor-stack/xsimd
requires:
  - Clang:(?!.*osx)
build_requires:
  - alibuild-recipe-tools
  - CMake
  - ninja
---

mkdir -p $INSTALLROOT
cd $BUILDDIR

cmake $SOURCEDIR                          \
      -G Ninja                            \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
