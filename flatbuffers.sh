package: flatbuffers
version: v24.3.25
source: https://github.com/google/flatbuffers
requires:
  - zlib
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
  - ninja
---
cmake "$SOURCEDIR"                                                                                                      \
      -G 'Ninja'                                                                                                        \
      -DFLATBUFFERS_BUILD_TESTS=OFF                                                                                     \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                                          

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
