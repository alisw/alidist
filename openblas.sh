package: OpenBLAS
version: "%(tag_basename)s"
tag: "v0.3.27"
source: https://github.com/xianyi/OpenBLAS.git
requires:
  - openmp
  - "GCC-Toolchain:(?!osx)"
license: BSD-3-Clause
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

for INTERFACE in LP64 ILP64; do
  BUILD_DIR="build-$INTERFACE"
  cmake -S "$SOURCEDIR" -B "$BUILD_DIR"                                    \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                              \
        -DDYNAMIC_ARCH=ON                                                  \
        -DBUILD_WITHOUT_LAPACK=OFF                                         \
        -DINTERFACE64="$([[ $INTERFACE = ILP64 ]] && echo ON || echo OFF)" \
        -DCMAKE_INSTALL_LIBDIR=lib                                         \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5                                 \
        -DBUILD_SHARED_LIBS=ON
  cmake --build "$BUILD_DIR" -- ${JOBS:+-j$JOBS}
  cmake --install "$BUILD_DIR"
done

# CMake's FindBLAS searches for libopenblas64 when the ILP64 interface is requested.
case $ARCHITECTURE in
  osx*) ln -sf libopenblas_64.dylib "$INSTALLROOT/lib/libopenblas64.dylib" ;;
  *)    ln -sf libopenblas_64.so "$INSTALLROOT/lib/libopenblas64.so" ;;
esac

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles




