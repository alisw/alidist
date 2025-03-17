package: onnx
version: "v1.17.0"
tag: v1.17.0
source: https://github.com/onnx/onnx
requires:
  - "GCC-Toolchain:(?!osx)"
  - protobuf
  - abseil
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
---
#!/bin/bash -e
CPPFLAFS="-I$ABSEIL_ROOT/include"  cmake "$SOURCEDIR"                             \
    -G Ninja \
    -DABSEIL_DIR=$ABSEIL_ROOT \
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON \
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
