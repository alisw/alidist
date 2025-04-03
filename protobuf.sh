package: protobuf
version: v29.3
tag: v29.3
source: https://github.com/protocolbuffers/protobuf
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
  - abseil
  - ninja
prepend_path:
  # The protobuf headers must match the protoc binary version, so prevent the
  # use of system headers by putting ours first in the path.
  PKG_CONFIG_PATH: "$PROTOBUF_ROOT/lib/pkgconfig"
---
#!/bin/bash -e
if [ -f $SOURCEDIR/cmake/CMakeLists.txt ]; then
  ALIBUILD_CMAKE_SOURCE_DIR=$SOURCEDIR/cmake
else
  ALIBUILD_CMAKE_SOURCE_DIR=$SOURCEDIR
fi
cmake -S "$ALIBUILD_CMAKE_SOURCE_DIR"                  \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -Dprotobuf_BUILD_TESTS=NO             \
    -Dprotobuf_MODULE_COMPATIBLE=YES      \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF      \
    -Dprotobuf_ABSL_PROVIDER=package      \
    -DABSL_ROOT_DIR=$ABSEIL_ROOT          \
    -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . -- ${JOBS:+-j$JOBS} install
sed -i.bak 's|absl/log/absl_log.h|absl/log/vlog_is_on.h|' $INSTALLROOT/include/google/protobuf/io/coded_stream.h
rm $INSTALLROOT/include/google/protobuf/io/coded_stream.h.bak

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
