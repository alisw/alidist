package: SOFIE
version: "%(tag_basename)s"
tag: alice-custom
source: https://github.com/ChSonnabend/SOFIE.git
license: LGPL-2.1
requires:
  - alpaka
  - sofieBLAS
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
incremental_recipe: |
  cmake --build . --target install ${JOBS:+-j $JOBS}
  mkdir -p etc/modulefiles "$INSTALLROOT/etc/modulefiles"
  alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"
  printf '\nsetenv SOFIE_ROOT $::env(BASEDIR)/SOFIE/$version\n' >> "etc/modulefiles/$PKGNAME"
  rsync -a etc/modulefiles/ "$INSTALLROOT/etc/modulefiles/"
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
  -DSOFIE_BUILD_TESTS=OFF \
  -DSOFIE_BENCHMARK=OFF \
  -DSOFIE_ALPAKA_INCLUDE_DIR="$ALPAKA_ROOT/include" \
  -DSOFIE_BLAS_INCLUDE_DIR="$SOFIEBLAS_ROOT/include"
cmake --build . --target install ${JOBS:+-j $JOBS}
mkdir -p etc/modulefiles "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"
printf '\nsetenv SOFIE_ROOT $::env(BASEDIR)/SOFIE/$version\n' >> "etc/modulefiles/$PKGNAME"
rsync -a etc/modulefiles/ "$INSTALLROOT/etc/modulefiles/"
