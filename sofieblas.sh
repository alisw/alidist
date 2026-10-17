package: sofieBLAS
version: "%(short_hash)s"
tag: 1977fbb89dcb562a75d628c06fd3a5bb74ec1076
source: https://github.com/ML4EP/sofieBLAS.git
license: GPL-3.0
requires:
  - alpaka
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DSOFIEBLAS_BUILD_TESTS=OFF \
  -DSOFIEBLAS_BUILD_BENCHMARKS=OFF
cmake --install .
mkdir -p etc/modulefiles "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "etc/modulefiles/$PKGNAME"
printf '\nsetenv SOFIEBLAS_ROOT $::env(BASEDIR)/sofieBLAS/$version\n' >> "etc/modulefiles/$PKGNAME"
rsync -a etc/modulefiles/ "$INSTALLROOT/etc/modulefiles/"
