package: re2
version: "2019-09-01"
source: https://github.com/google/re2
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
  - abseil
prefer_system: .*
prefer_system_check: |
  printf "#include \"re2/re2.h\"\n" | cc -I$(brew --prefix re2)/include -I$(brew --prefix abseil)/include -xc++ -std=c++20 - -c -o /dev/null
---
#!/bin/sh
cmake $SOURCEDIR                           \
      -G Ninja                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
