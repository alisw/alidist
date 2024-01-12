package: flatbuffers
version: v23.5.26
source: https://github.com/google/flatbuffers
requires:
  - zlib
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR"                          \
      -G 'Unix Makefiles'                   \
      -DFLATBUFFERS_BUILD_TESTS=OFF         \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-error=unused-but-set-variable"
# LLVM 15 requires -Wno-error=unused-but-set-variable to compile
# flatbuffers, but GCC earlier LLVM versions don't understand this
# option, so we need -Wno-unknown-warning (for GCC) and
# -Wno-unknown-warning-option (for Clang) as well.

make ${JOBS:+-j $JOBS}
make install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
