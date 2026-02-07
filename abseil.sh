package: abseil
version: "%(tag_basename)s"
tag: "20240722.0"
requires:
  - "GCC-Toolchain:(?!osx)"
license: Apache v2
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
  - ninja
source: https://github.com/abseil/abseil-cpp
#prefer_system: "osx"
#prefer_system_check: |
#  printf '#include <absl/container/flat_hash_map.h>' | c++ -std=c++20 -I"$(brew --prefix abseil)/include" -c -xc++ - >/dev/null
#  printf "alibuild_system_replace: abseil-brew-$(brew info --json abseil | jq -r '.[0].installed[0].version')"
#  brew info --json abseil | jq -r '.[0].installed[0].version'
#  exit 1
#prefer_system_replacement_specs:
#  "abseil-brew.*":
#    version: "%(key)s"
#    env:
#      ABSEIL_ROOT: $(brew --prefix abseil)
#      ABSEIL_VERSION: $(brew info --json abseil | jq -r '.[0].installed[0].version')
#      ABSEIL_REVISION: "1"
#    prepend_path:
#      PKG_CONFIG_PATH: "$ABSEIL_ROOT/lib/pkgconfig"
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
prepend_path:
  PKG_CONFIG_PATH: "$ABSEIL_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

mkdir -p $INSTALLROOT
cmake $SOURCEDIR                             \
  -G Ninja                                   \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}    \
  -DCMAKE_INSTALL_LIBDIR=lib                 \
  -DBUILD_TESTING=OFF                        \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin --cmake > "$MODULEFILE"
