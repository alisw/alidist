package: librdkafka
version: "%(tag_basename)s"
tag: v2.3.0
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
  - CMake
source: https://github.com/edenhill/librdkafka
---
#!/bin/bash -ex
cmake -H"$SOURCEDIR"                        \
      -B"$SOURCEDIR/_cmake_build"           \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_INSTALL_LIBDIR=lib            \
      -DENABLE_LZ4_EXT=OFF                  \
      -DRDKAFKA_BUILD_TESTS=OFF             \
      -DRDKAFKA_BUILD_EXAMPLES=OFF
cmake --build "$SOURCEDIR/_cmake_build" --target install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
