package: OpenBLAS
version: "%(tag_basename)s"
tag: "v0.3.27"
source: https://github.com/xianyi/OpenBLAS.git
requires:
  - openmp
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

cmake $SOURCEDIR                                 \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DDYNAMIC_ARCH=ON                          \
      -DBUILD_WITHOUT_LAPACK=OFF                 \
      -DCMAKE_INSTALL_LIBDIR=lib                 \
      -DBUILD_SHARED_LIBS=ON                     
make ${JOBS:+-j$JOBS}
make install 

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles




