package: libuv
version: v1.40.0
source: https://github.com/libuv/libuv
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include <uv.h>" | c++ -I$(brew --prefix libuv)/include -xc++ - -c -o /dev/null 2>&1
---
#!/bin/sh
cmake $SOURCEDIR                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                    \
      -DCMAKE_INSTALL_LIBDIR=lib

make ${JOBS+-j $JOBS}
make install

mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
