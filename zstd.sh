package: zstd
version: "%(tag_basename)s"
tag: v1.5.7
license: BSD-3-Clause
source: https://github.com/facebook/zstd
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$ZSTD_ROOT/lib/pkgconfig"
prefer_system: ".*"
prefer_system_check: |
  ZSTD_PREFIX=$(brew --prefix --installed zstd 2>/dev/null)
  if ! printf "#include <zstd.h>\n" | cc -xc - ${ZSTD_PREFIX:+-I$ZSTD_PREFIX/include} -c -M 2>&1; then
    printf "libzstd was not found.\n"
    printf " * On RHEL-compatible systems you probably need: libzstd libzstd-devel\n"
    printf " * On Ubuntu-compatible systems you probably need: libzstd1 libzstd-dev\n"
    printf " * On macOS you probably need: brew install zstd\n"
    exit 1
  fi
---
#!/bin/bash -e
# zstd keeps its CMake build under build/cmake. The tools are kept (the zstd
# command is handy for inspecting data); tests and contrib are not built.
cmake -S "$SOURCEDIR/build/cmake" -B build -G Ninja \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"          \
      -DCMAKE_INSTALL_LIBDIR=lib                     \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON           \
      -DCMAKE_INSTALL_NAME_DIR="$INSTALLROOT/lib"    \
      -DZSTD_BUILD_TESTS=OFF                         \
      -DZSTD_BUILD_CONTRIB=OFF
cmake --build build -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > "$MODULEDIR/$PKGNAME"
