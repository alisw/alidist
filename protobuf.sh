package: protobuf
version: v21.9
source: https://github.com/protocolbuffers/protobuf
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prepend_path:
  # The protobuf headers must match the protoc binary version, so prevent the
  # use of system headers by putting ours first in the path.
  PKG_CONFIG_PATH: "$PROTOBUF_ROOT/lib/pkgconfig"
---
#!/bin/bash -e
cmake "$SOURCEDIR/cmake"                  \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -Dprotobuf_BUILD_TESTS=NO             \
    -Dprotobuf_MODULE_COMPATIBLE=YES      \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF      \
    -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j $JOBS}
make install

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
