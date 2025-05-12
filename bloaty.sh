package: bloaty
version: "%(tag_basename)s"
tag: v1.1-alice2
requires:
  - "GCC-Toolchain:(?!osx)"
  - capstone
  - abseil
  - re2
  - protobuf
  - zlib
build_requires:
  - CMake
  - ninja
source: https://github.com/alisw/bloaty
---
#!/bin/bash -e

cmake $SOURCEDIR                                    \
  -G Ninja                                          \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}           \
  -DBUILD_TESTING=OFF                 \
  -DBLOATY_PREFER_SYSTEM_CAPSTONE=TRUE \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS:+-j$JOBS} install


#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
